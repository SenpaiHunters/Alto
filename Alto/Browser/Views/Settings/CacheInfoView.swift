import OpenADK
import SwiftUI

struct CacheInfoView: View {
    @State private var cacheStats = (diskCount: 0, memoryCount: 0, totalSizeBytes: 0)
    @State private var refreshTimer: Timer?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "externaldrive")
                    .foregroundColor(.blue)
                Text("Disk Cache: \(cacheStats.diskCount) items")
                    .font(.caption)
            }

            HStack {
                Image(systemName: "memorychip")
                    .foregroundColor(.green)
                Text("Memory Cache: \(cacheStats.memoryCount) items")
                    .font(.caption)
            }

            HStack {
                Image(systemName: "chart.bar")
                    .foregroundColor(.orange)
                Text("Cache Size: \(formatBytes(cacheStats.totalSizeBytes))")
                    .font(.caption)
            }
        }
        .foregroundColor(.secondary)
        .onAppear {
            updateCacheStats()
            startRefreshTimer()
        }
        .onDisappear {
            stopRefreshTimer()
        }
    }

    private func updateCacheStats() {
        cacheStats = Alto.shared.faviconManager.getCacheStats()
    }

    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            updateCacheStats()
        }
    }

    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// #Preview {
//     CacheInfoView()
//         .padding()
// }
