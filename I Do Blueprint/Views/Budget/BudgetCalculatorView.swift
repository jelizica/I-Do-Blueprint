import SwiftUI

struct BudgetCalculatorView: View {
    @StateObject private var viewModel = BudgetCalculatorViewModel()
    @EnvironmentObject var settingsStore: SettingsStoreV2

    var body: some View {
        VStack(spacing: 0) {
            // Scenario Selector Header
            BudgetCalculatorHeader(
                selectedScenarioId: Binding(
                    get: { viewModel.selectedScenario?.id },
                    set: { _ in }
                ),
                scenarios: viewModel.scenarios,
                onScenarioChange: { scenario in
                    viewModel.selectScenario(scenario)
                    Task {
                        await viewModel.loadContributions()
                    }
                },
                onAddScenario: {
                    viewModel.showAddScenarioSheet = true
                },
                onDeleteScenario: {
                    if let scenario = viewModel.selectedScenario {
                        Task { await viewModel.deleteScenario(scenario) }
                    }
                }
            )
            .padding(EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24))
            .background(Color(NSColor.controlBackgroundColor))

            ScrollView {
                HStack(alignment: .top, spacing: 24) {
                    // Left Side - Budget Inputs
                    VStack(alignment: .leading, spacing: 24) {
                        BudgetInputsSection(
                            calculationStartDate: $viewModel.editedCalculationStartDate,
                            partner1Monthly: $viewModel.editedPartner1Monthly,
                            partner2Monthly: $viewModel.editedPartner2Monthly,
                            hasUnsavedChanges: viewModel.hasUnsavedChanges,
                            weddingDate: viewModel.editedWeddingDate,
                            partner1Name: partner1Name,
                            partner2Name: partner2Name,
                            onFieldChanged: {
                                viewModel.markFieldChanged()
                            },
                            onSave: {
                                Task { await viewModel.saveChanges() }
                            }
                        )

                        GiftsContributionsSection(
                            totalGifts: viewModel.totalGifts,
                            totalExternal: viewModel.totalExternal,
                            contributions: viewModel.contributions,
                            onAddContribution: {
                                viewModel.showAddContributionSheet = true
                            },
                            onLinkGifts: {
                                Task {
                                    await viewModel.loadAvailableGifts()
                                    viewModel.showLinkGiftsSheet = true
                                }
                            },
                            onEditContribution: { contribution in
                                Task {
                                    await viewModel.startEditingGift(contributionId: contribution.id)
                                }
                            },
                            onDeleteContribution: { contribution in
                                Task {
                                    await viewModel.deleteContribution(contribution)
                                }
                            }
                        )
                    }
                    .frame(maxWidth: .infinity)

                    // Right Side - Affordability Results
                    VStack(alignment: .leading, spacing: 24) {
                        AffordabilityResultsSection(
                            totalAffordableBudget: viewModel.totalAffordableBudget,
                            alreadyPaid: viewModel.alreadyPaid,
                            projectedSavings: viewModel.projectedSavings,
                            monthsLeft: viewModel.monthsLeft,
                            progressPercentage: viewModel.progressPercentage
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(24)
            }
        }
        .task {
            // Load scenarios first
            await viewModel.loadScenarios()
        }
        .onChange(of: settingsStore.hasLoaded) { _, loaded in
            // When settings finish loading, set the wedding date
            if loaded {
                let weddingDateFromSettings = settingsStore.settings.global.weddingDate
                AppLogger.ui.info("BudgetCalculatorView: Settings loaded, wedding date: '\(weddingDateFromSettings)'")

                if !weddingDateFromSettings.isEmpty {
                    AppLogger.ui.info("BudgetCalculatorView: Setting wedding date to: '\(weddingDateFromSettings)'")
                    viewModel.setWeddingDate(weddingDateFromSettings)
                } else {
                    AppLogger.ui.warning("BudgetCalculatorView: Wedding date is empty")
                }
            }
        }
        .onChange(of: settingsStore.settings.global.weddingDate) { _, newDate in
            // Only update if the date is not empty
            if !newDate.isEmpty {
                AppLogger.ui.info("BudgetCalculatorView: Wedding date changed to: '\(newDate)'")
                viewModel.setWeddingDate(newDate)
            }
        }
        .onAppear {
            // If settings are already loaded when view appears, set the wedding date immediately
            if settingsStore.hasLoaded {
                let weddingDateFromSettings = settingsStore.settings.global.weddingDate
                if !weddingDateFromSettings.isEmpty {
                    AppLogger.ui.info("BudgetCalculatorView.onAppear: Setting wedding date to: '\(weddingDateFromSettings)'")
                    viewModel.setWeddingDate(weddingDateFromSettings)
                }
            }
        }
        .sheet(isPresented: $viewModel.showAddScenarioSheet) {
            BudgetCalculatorAddScenarioSheet(onSave: { name in
                Task {
                    await viewModel.createScenario(name: name)
                    viewModel.showAddScenarioSheet = false
                }
            })
        }
        .sheet(isPresented: $viewModel.showAddContributionSheet) {
            BudgetCalculatorAddContributionSheet(onSave: { name, amount, type, date in
                Task {
                    await viewModel.addContribution(
                        name: name,
                        amount: amount,
                        type: type,
                        date: date
                    )
                    viewModel.showAddContributionSheet = false
                }
            })
        }
        .sheet(isPresented: $viewModel.showLinkGiftsSheet) {
            LinkGiftsSheet(
                availableGifts: viewModel.availableGifts,
                onLink: { giftIds in
                    Task {
                        await viewModel.linkGiftsToScenario(giftIds: giftIds)
                        viewModel.showLinkGiftsSheet = false
                    }
                }
            )
        }
        .sheet(isPresented: $viewModel.showEditGiftSheet) {
            if let gift = viewModel.editingGift {
                EditGiftSheet(
                    gift: gift,
                    onSave: { updatedGift in
                        Task {
                            await viewModel.updateGift(updatedGift)
                        }
                    },
                    onCancel: {
                        viewModel.showEditGiftSheet = false
                        viewModel.editingGift = nil
                    }
                )
            }
        }
    }

    // MARK: - Helper Properties

    private var partner1Name: String {
        let nickname = settingsStore.settings.global.partner1Nickname
        return nickname.isEmpty ? settingsStore.settings.global.partner1FullName : nickname
    }

    private var partner2Name: String {
        let nickname = settingsStore.settings.global.partner2Nickname
        return nickname.isEmpty ? settingsStore.settings.global.partner2FullName : nickname
    }
}

#Preview {
    BudgetCalculatorView()
        .environmentObject(SettingsViewModel())
}
