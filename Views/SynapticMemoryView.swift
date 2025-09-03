import SwiftUI
import Charts

struct SynapticMemoryView: View {
    @ObservedObject var manager = SynapticMemoryManager.shared
    @State private var query = ""
    @State private var vec: [Float] = []
    @State private var searchResults: [SynapticMemory] = []
    @State private var showAll = false

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Paste embedding comma separated", text: $query)
                    Button("Search") {
                        vec = query.split(separator: ",").compactMap { Float($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
                        if vec.count > 0 { searchResults = manager.findSimilar(embedding: vec) }
                    }
                }.padding()
                HStack {
                    Button("Recent 10") { showAll = false }
                        .font(.caption)
                        .padding()
                        .background(showAll ? Color.clear : Color.blue.opacity(0.2))
                        .cornerRadius(4)
                    Button("All Memories") { showAll = true }
                        .font(.caption)
                        .padding()
                        .background(showAll ? Color.blue.opacity(0.2) : Color.clear)
                        .cornerRadius(4)
                }
                .padding(.bottom, 2)

                // Simple histogram of memory creation
                Chart {
                    ForEach(histogramBuckets(), id: \.bucket) { bucket in
                        BarMark(
                            x: .value("Bucket", bucket.bucket),
                            y: .value("Count", bucket.count)
                        )
                    }
                }
                .frame(height: 120)
                .padding([.horizontal, .top])

                List {
                    SwiftUI.ForEach(showAll ? manager.memories : Array(manager.memories.suffix(10))) { mem in
                        VStack(alignment: .leading) {
                            Text(mem.text)
                            Text("Embedding: [\(mem.vectorEmbedding.prefix(3).map { String(format: "%.2f", $0) }.joined(separator: ", ")) ...]")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(mem.createdAt, style: .relative)
                                .font(.caption2).foregroundColor(.gray)
                        }
                    }
                }
                
                if !searchResults.isEmpty {
                    Text("Search Results: top \(searchResults.count)")
                        .font(.caption).foregroundColor(.blue)
                    List(searchResults) { mem in
                        VStack(alignment: .leading) {
                            Text(mem.text)
                            Text("Created: \(mem.createdAt, style: .relative)")
                                .font(.caption2)
                        }
                    }.frame(maxHeight: 160)
                }
            }
            .navigationTitle("Synaptic Memory")
        }
    }

    struct MemoryHistogramBucket {
        let bucket: String
        let count: Int
    }
    
    func histogramBuckets() -> [MemoryHistogramBucket] {
        // Bar chart of memories per day for last week
        let memories = manager.memories
        let cal = Calendar.current
        var buckets: [String: Int] = [:]
        for mem in memories {
            let day = cal.startOfDay(for: mem.createdAt)
            let label = DateFormatter.localizedString(from: day, dateStyle: .short, timeStyle: .none)
            buckets[label, default: 0] += 1
        }
        return buckets.map { MemoryHistogramBucket(bucket: $0.key, count: $0.value) }
            .sorted { $0.bucket < $1.bucket }
    }
}