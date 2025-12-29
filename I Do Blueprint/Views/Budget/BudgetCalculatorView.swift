import SwiftUI

struct BudgetCalculatorView: View {
    @EnvironmentObject private var budgetStore: BudgetStoreV2
    @EnvironmentObject var settingsStore: SettingsStoreV2

    var body: some View {
        VStack(spacing: 0) {
            // Scenario Selector Header
            BudgetCalculatorHeader(
                selectedScenarioId: Binding(
                    get: { budgetStore.affordability.selectedScenario?.id },
                    set: { _ in }
                ),
                scenarios: budgetStore.affordability.scenarios,
                onScenarioChange: { scenario in
                    budgetStore.affordability.selectScenario(scenario)
                    Task {
                        await budgetStore.affordability.loadContributions()
                    }
                },
                onAddScenario: {
                    budgetStore.affordability.showAddScenarioSheet = true
                },
                onDeleteScenario: {
                    if let scenario = budgetStore.affordability.selectedScenario {
                        Task { await budgetStore.affordability.deleteScenario(scenario) }
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
                            calculationStartDate: $budgetStore.affordability.editedCalculationStartDate,
                            partner1Monthly: $budgetStore.affordability.editedPartner1Monthly,
                            partner2Monthly: $budgetStore.affordability.editedPartner2Monthly,
                            hasUnsavedChanges: budgetStore.affordability.hasUnsavedChanges,
                            weddingDate: budgetStore.affordability.editedWeddingDate,
                            partner1Name: partner1Name,
                            partner2Name: partner2Name,
                            onFieldChanged: {
                                budgetStore.affordability.markFieldChanged()
                            },
                            onSave: {
                                Task { await budgetStore.affordability.saveChanges() }
                            }
                        )

                        GiftsContributionsSection(
                            totalGifts: budgetStore.affordability.totalGifts,
                            totalExternal: budgetStore.affordability.totalExternal,
                            contributions: budgetStore.affordability.contributions,
                            onAddContribution: {
                                budgetStore.affordability.showAddContributionSheet = true
                            },
                            onLinkGifts: {
                                Task {
                                    await budgetStore.affordability.loadAvailableGifts()
                                    budgetStore.affordability.showLinkGiftsSheet = true
                                }
                            },
                            onEditContribution: { contribution in
                                Task {
                                    await budgetStore.affordability.startEditingGift(contributionId: contribution.id)
                                    budgetStore.affordability.showEditGiftSheet = true
                                }
                            },
                            onDeleteContribution: { contribution in
                                Task {
                                    await budgetStore.affordability.deleteContribution(contribution)
                                }
                            }
                        )
                    }
                    .frame(maxWidth: .infinity)

                    // Right Side - Affordability Results
                    VStack(alignment: .leading, spacing: 24) {
                        AffordabilityResultsSection(
                            totalAffordableBudget: budgetStore.affordability.totalAffordableBudget,
                            alreadyPaid: budgetStore.affordability.alreadyPaid,
                            projectedSavings: budgetStore.affordability.projectedSavings,
                            monthsLeft: budgetStore.affordability.monthsLeft,
                            progressPercentage: budgetStore.affordability.progressPercentage
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(Spacing.xxl)
            }
        }
        .task {
            // Load scenarios first
            await budgetStore.affordability.loadScenarios()
        }
        .onChange(of: settingsStore.hasLoaded) { _, loaded in
            // When settings finish loading, set the wedding date
            if loaded {
                let weddingDateFromSettings = settingsStore.settings.global.weddingDate
                AppLogger.ui.info("BudgetCalculatorView: Settings loaded, wedding date: '\(weddingDateFromSettings)'")

                if !weddingDateFromSettings.isEmpty {
                    AppLogger.ui.info("BudgetCalculatorView: Setting wedding date to: '\(weddingDateFromSettings)'")
                    budgetStore.affordability.setWeddingDate(weddingDateFromSettings)
                } else {
                    AppLogger.ui.warning("BudgetCalculatorView: Wedding date is empty")
                }
            }
        }
        .onChange(of: settingsStore.settings.global.weddingDate) { _, newDate in
            // Only update if the date is not empty
            if !newDate.isEmpty {
                AppLogger.ui.info("BudgetCalculatorView: Wedding date changed to: '\(newDate)'")
                budgetStore.affordability.setWeddingDate(newDate)
            }
        }
        .onAppear {
            // If settings are already loaded when view appears, set the wedding date immediately
            if settingsStore.hasLoaded {
                let weddingDateFromSettings = settingsStore.settings.global.weddingDate
                if !weddingDateFromSettings.isEmpty {
                    AppLogger.ui.info("BudgetCalculatorView.onAppear: Setting wedding date to: '\(weddingDateFromSettings)'")
                    budgetStore.affordability.setWeddingDate(weddingDateFromSettings)
                }
            }
        }
        .sheet(isPresented: $budgetStore.affordability.showAddScenarioSheet) {
            BudgetCalculatorAddScenarioSheet(onSave: { name in
                Task {
                    await budgetStore.affordability.createScenario(name: name)
                    budgetStore.affordability.showAddScenarioSheet = false
                }
            })
        }
        .sheet(isPresented: $budgetStore.affordability.showAddContributionSheet) {
            BudgetCalculatorAddContributionSheet(onSave: { name, amount, type, date in
                Task {
                    await budgetStore.affordability.addContribution(
                        name: name,
                        amount: amount,
                        type: type,
                        date: date
                    )
                    budgetStore.affordability.showAddContributionSheet = false
                }
            })
        }
        .sheet(isPresented: $budgetStore.affordability.showLinkGiftsSheet) {
            LinkGiftsSheet(
                availableGifts: budgetStore.affordability.availableGifts,
                onLink: { giftIds in
                    Task {
                        await budgetStore.affordability.linkGifts(giftIds: giftIds)
                        budgetStore.affordability.showLinkGiftsSheet = false
                    }
                }
            )
        }
        .sheet(isPresented: $budgetStore.affordability.showEditGiftSheet) {
            if let gift = budgetStore.affordability.editingGift {
                EditGiftSheet(
                    gift: gift,
                    onSave: { updatedGift in
                        Task {
                            await budgetStore.affordability.updateGift(updatedGift)
                        }
                    },
                    onCancel: {
                        budgetStore.affordability.showEditGiftSheet = false
                        budgetStore.affordability.editingGift = nil
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
