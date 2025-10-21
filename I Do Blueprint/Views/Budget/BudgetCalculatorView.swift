import SwiftUI

struct BudgetCalculatorView: View {
    @EnvironmentObject private var budgetStore: BudgetStoreV2
    @EnvironmentObject var settingsStore: SettingsStoreV2

    var body: some View {
        VStack(spacing: 0) {
            // Scenario Selector Header
            BudgetCalculatorHeader(
                selectedScenarioId: Binding(
                    get: { budgetStore.selectedScenario?.id },
                    set: { _ in }
                ),
                scenarios: budgetStore.scenarios,
                onScenarioChange: { scenario in
                    budgetStore.selectScenario(scenario)
                    Task {
                        await budgetStore.loadContributions()
                    }
                },
                onAddScenario: {
                    budgetStore.showAddScenarioSheet = true
                },
                onDeleteScenario: {
                    if let scenario = budgetStore.selectedScenario {
                        Task { await budgetStore.deleteScenario(scenario) }
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
                            calculationStartDate: $budgetStore.editedCalculationStartDate,
                            partner1Monthly: $budgetStore.editedPartner1Monthly,
                            partner2Monthly: $budgetStore.editedPartner2Monthly,
                            hasUnsavedChanges: budgetStore.hasUnsavedChanges,
                            weddingDate: budgetStore.editedWeddingDate,
                            partner1Name: partner1Name,
                            partner2Name: partner2Name,
                            onFieldChanged: {
                                budgetStore.markFieldChanged()
                            },
                            onSave: {
                                Task { await budgetStore.saveChanges() }
                            }
                        )

                        GiftsContributionsSection(
                            totalGifts: budgetStore.totalGifts,
                            totalExternal: budgetStore.totalExternal,
                            contributions: budgetStore.contributions,
                            onAddContribution: {
                                budgetStore.showAddContributionSheet = true
                            },
                            onLinkGifts: {
                                Task {
                                    await budgetStore.loadAvailableGifts()
                                    budgetStore.showLinkGiftsSheet = true
                                }
                            },
                            onEditContribution: { contribution in
                                Task {
                                    await budgetStore.startEditingGift(contributionId: contribution.id)
                                    budgetStore.showEditGiftSheet = true
                                }
                            },
                            onDeleteContribution: { contribution in
                                Task {
                                    await budgetStore.deleteContribution(contribution)
                                }
                            }
                        )
                    }
                    .frame(maxWidth: .infinity)

                    // Right Side - Affordability Results
                    VStack(alignment: .leading, spacing: 24) {
                        AffordabilityResultsSection(
                            totalAffordableBudget: budgetStore.totalAffordableBudget,
                            alreadyPaid: budgetStore.alreadyPaid,
                            projectedSavings: budgetStore.projectedSavings,
                            monthsLeft: budgetStore.monthsLeft,
                            progressPercentage: budgetStore.progressPercentage
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(24)
            }
        }
        .task {
            // Load scenarios first
            await budgetStore.loadScenarios()
        }
        .onChange(of: settingsStore.hasLoaded) { _, loaded in
            // When settings finish loading, set the wedding date
            if loaded {
                let weddingDateFromSettings = settingsStore.settings.global.weddingDate
                AppLogger.ui.info("BudgetCalculatorView: Settings loaded, wedding date: '\(weddingDateFromSettings)'")

                if !weddingDateFromSettings.isEmpty {
                    AppLogger.ui.info("BudgetCalculatorView: Setting wedding date to: '\(weddingDateFromSettings)'")
                    budgetStore.setWeddingDate(weddingDateFromSettings)
                } else {
                    AppLogger.ui.warning("BudgetCalculatorView: Wedding date is empty")
                }
            }
        }
        .onChange(of: settingsStore.settings.global.weddingDate) { _, newDate in
            // Only update if the date is not empty
            if !newDate.isEmpty {
                AppLogger.ui.info("BudgetCalculatorView: Wedding date changed to: '\(newDate)'")
                budgetStore.setWeddingDate(newDate)
            }
        }
        .onAppear {
            // If settings are already loaded when view appears, set the wedding date immediately
            if settingsStore.hasLoaded {
                let weddingDateFromSettings = settingsStore.settings.global.weddingDate
                if !weddingDateFromSettings.isEmpty {
                    AppLogger.ui.info("BudgetCalculatorView.onAppear: Setting wedding date to: '\(weddingDateFromSettings)'")
                    budgetStore.setWeddingDate(weddingDateFromSettings)
                }
            }
        }
        .sheet(isPresented: $budgetStore.showAddScenarioSheet) {
            BudgetCalculatorAddScenarioSheet(onSave: { name in
                Task {
                    await budgetStore.createScenario(name: name)
                    budgetStore.showAddScenarioSheet = false
                }
            })
        }
        .sheet(isPresented: $budgetStore.showAddContributionSheet) {
            BudgetCalculatorAddContributionSheet(onSave: { name, amount, type, date in
                Task {
                    await budgetStore.addContribution(
                        name: name,
                        amount: amount,
                        type: type,
                        date: date
                    )
                    budgetStore.showAddContributionSheet = false
                }
            })
        }
        .sheet(isPresented: $budgetStore.showLinkGiftsSheet) {
            LinkGiftsSheet(
                availableGifts: budgetStore.availableGifts,
                onLink: { giftIds in
                    Task {
                        await budgetStore.linkGifts(giftIds: giftIds)
                        budgetStore.showLinkGiftsSheet = false
                    }
                }
            )
        }
        .sheet(isPresented: $budgetStore.showEditGiftSheet) {
            if let gift = budgetStore.editingGift {
                EditGiftSheet(
                    gift: gift,
                    onSave: { updatedGift in
                        Task {
                            await budgetStore.updateGift(updatedGift)
                        }
                    },
                    onCancel: {
                        budgetStore.showEditGiftSheet = false
                        budgetStore.editingGift = nil
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
        .environmentObject(SettingsStoreV2())
}
