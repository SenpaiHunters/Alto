//
//  AdBlockSettingsView.swift
//  Alto
//
//  Created by Kami on 23/06/2025.
//

import SwiftUI

// MARK: - AdBlockSettingsView

struct AdBlockSettingsView: View {
    @StateObject private var viewModel = ABViewModel()
    @StateObject private var abManager = ABManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with main toggle and stats
                adBlockHeaderSection

                // Quick statistics
                statisticsSection

                // Filter lists management
                filterListsSection

                // Whitelist management
                whitelistSection
            }
            .padding(20)
        }
        .sheet(isPresented: $viewModel.isShowingAddFilterSheet) {
            addFilterListSheet
        }
        .sheet(isPresented: $viewModel.isShowingWhitelistSheet) {
            addWhitelistDomainSheet
        }
        .sheet(isPresented: $viewModel.isShowingStatistics) {
            statisticsDetailSheet
        }
    }

    // MARK: - Header Section

    private var adBlockHeaderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.title2)
                    .foregroundColor(viewModel.isEnabled ? .green : .secondary)

                Text("AdBlock")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Toggle("", isOn: $viewModel.isEnabled)
                    .toggleStyle(SwitchToggleStyle())
            }

            Text(viewModel.isEnabled ? "Blocking ads and trackers" : "Ad blocking disabled")
                .font(.caption)
                .foregroundColor(.secondary)

            if viewModel.isEnabled {
                Text(viewModel.activeFiltersSummary)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(10)
    }

    // MARK: - Statistics Section

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Statistics")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Button("View Details") {
                    viewModel.isShowingStatistics = true
                }
                .buttonStyle(.borderless)
                .foregroundColor(.accentColor)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                statCard(
                    title: "Blocked",
                    value: viewModel.totalBlockedRequests.formatted(),
                    icon: "shield.checkered",
                    color: .green
                )

                statCard(
                    title: "Session",
                    value: viewModel.blockedRequestsThisSession.formatted(),
                    icon: "clock",
                    color: .blue
                )

                statCard(
                    title: "Percentage",
                    value: viewModel.globalStats.formattedBlockingPercentage,
                    icon: "chart.pie",
                    color: .orange
                )

                statCard(
                    title: "Saved",
                    value: viewModel.globalStats.formattedBandwidthSaved,
                    icon: "arrow.down.circle",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(10)
    }

    // MARK: - Filter Lists Section

    private var filterListsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Filter Lists")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                if viewModel.isUpdatingFilters {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Button("Update All") {
                        viewModel.updateAllFilterLists()
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.accentColor)
                }

                Button("Add List") {
                    viewModel.isShowingAddFilterSheet = true
                }
                .buttonStyle(.borderless)
                .foregroundColor(.accentColor)
            }

            LazyVStack(spacing: 8) {
                ForEach(viewModel.filterListsByCategory, id: \.category) { categoryGroup in
                    filterListCategorySection(categoryGroup.category, lists: categoryGroup.lists)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(10)
    }

    // MARK: - Whitelist Section

    private var whitelistSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Whitelisted Domains")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Button("Add Domain") {
                    viewModel.isShowingWhitelistSheet = true
                }
                .buttonStyle(.borderless)
                .foregroundColor(.accentColor)
            }

            if viewModel.sortedWhitelistedDomains.isEmpty {
                Text("No whitelisted domains")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                LazyVStack(spacing: 4) {
                    ForEach(viewModel.sortedWhitelistedDomains, id: \.self) { domain in
                        whitelistDomainRow(domain)
                    }
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(10)
    }

    // MARK: - Helper Views

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.textBackgroundColor))
        .cornerRadius(8)
    }

    private func filterListCategorySection(_ category: ABFilterCategory, lists: [ABFilterList]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: category.iconName)
                    .foregroundColor(.secondary)

                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Spacer()
            }

            ForEach(lists) { filterList in
                filterListRow(filterList)
            }
        }
    }

    private func filterListRow(_ filterList: ABFilterList) -> some View {
        HStack {
            Toggle("", isOn: .constant(filterList.isEnabled))
                .toggleStyle(CheckboxToggleStyle())
                .onTapGesture {
                    viewModel.toggleFilterList(filterList)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(filterList.name)
                    .font(.body)

                Text(filterList.formattedLastUpdate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if !filterList.isBuiltIn {
                Button("Remove") {
                    viewModel.removeFilterList(filterList)
                }
                .buttonStyle(.borderless)
                .foregroundColor(.red)
                .font(.caption)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(.textBackgroundColor))
        .cornerRadius(6)
    }

    private func whitelistDomainRow(_ domain: String) -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)

            Text(domain)
                .font(.body)

            Spacer()

            Button("Remove") {
                viewModel.removeFromWhitelist(domain)
            }
            .buttonStyle(.borderless)
            .foregroundColor(.red)
            .font(.caption)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(.textBackgroundColor))
        .cornerRadius(6)
    }

    // MARK: - Sheets

    private var addFilterListSheet: some View {
        Form {
            Section("Filter List Details") {
                TextField("Name", text: $viewModel.newFilterListName)
                TextField("URL", text: $viewModel.newFilterListURL)
                    .textContentType(.URL)
            }

            Section("Examples") {
                Text("• EasyList: https://easylist.to/easylist/easylist.txt")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("• EasyPrivacy: https://easylist.to/easylist/easyprivacy.txt")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Add Filter List")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    viewModel.isShowingAddFilterSheet = false
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Add") {
                    viewModel.addCustomFilterList()
                }
                .disabled(!viewModel.canAddFilterList)
            }
        }
        .frame(width: 400, height: 300)
    }

    private var addWhitelistDomainSheet: some View {
        Form {
            Section("Domain Details") {
                TextField("Domain (e.g., example.com)", text: $viewModel.newWhitelistDomain)
                    .textContentType(.URL)
            }

            Section("Note") {
                Text(
                    "Whitelisted domains will not have ads blocked. This is useful for sites that break when ads are blocked."
                )
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Add Whitelisted Domain")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    viewModel.isShowingWhitelistSheet = false
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Add") {
                    viewModel.addToWhitelist()
                }
                .disabled(!viewModel.canAddWhitelistDomain)
            }
        }
        .frame(width: 400, height: 250)
    }

    private var statisticsDetailSheet: some View {
        Form {
            Section("Global Statistics") {
                Text(viewModel.formattedGlobalStats)
                    .font(.system(.body, design: .monospaced))
            }

            Section("Top Blocked Domains") {
                ForEach(viewModel.getTopBlockedDomains().prefix(10), id: \.domain) { item in
                    HStack {
                        Text(item.domain)
                            .font(.body)
                        Spacer()
                        Text("\(item.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section("Actions") {
                Button("Reset Statistics") {
                    viewModel.resetStatistics()
                    viewModel.isShowingStatistics = false
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Detailed Statistics")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    viewModel.isShowingStatistics = false
                }
            }
        }
        .frame(width: 500, height: 600)
    }
}

// MARK: - CheckboxToggleStyle

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? .accentColor : .secondary)
                .onTapGesture {
                    configuration.isOn.toggle()
                }

            configuration.label
        }
    }
}
