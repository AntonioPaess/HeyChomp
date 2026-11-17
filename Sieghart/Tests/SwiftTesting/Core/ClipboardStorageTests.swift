import AppKit
import Foundation
import Testing

extension MacContractsTests {
  @Suite(.tags(.clipboard, .localIntegration)) @MainActor
  struct ClipboardStorageTests {
    @Test("G12.06 old writes are ignored and an existing directory remains private")
    func diskRevisions() async throws {
      let now = Date(timeIntervalSince1970: 1_800_000_000)
      var pinned = ClipboardEntry(
        payload: ClipboardPayload(kind: .text, text: "Pinned fixture"), copiedAt: now,
        sourceName: "Fixture", sourceBundle: "fixture")
      pinned.pinned = true
      let temporary = FileManager.default.temporaryDirectory.appendingPathComponent(
        "Sieghart-Clipboard-\(UUID())")
      defer { try? FileManager.default.removeItem(at: temporary) }
      try FileManager.default.createDirectory(
        at: temporary, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o755])
      let file = temporary.appendingPathComponent("history.json")
      let disk = LocalClipboardStorage(url: file)
      try await disk.save([pinned], revision: 2)
      try await disk.save([], revision: 1)
      let diskItems = try await disk.load()
      #expect(diskItems == [pinned])
      let fileAttributes = try FileManager.default.attributesOfItem(atPath: file.path)
      let permission = try #require(fileAttributes[.posixPermissions] as? NSNumber).intValue
      #expect(permission == 0o600)
      let parentAttributes = try FileManager.default.attributesOfItem(atPath: temporary.path)
      let parentPermission = try #require(parentAttributes[.posixPermissions] as? NSNumber).intValue
      #expect(parentPermission == 0o700, "An existing history directory is private too")
    }

    @Test("G12.08 Imagens ficam fora do índice, são gravadas uma vez e saem do disco quando o item sai")
    func mediaOutsideIndex() async throws {
      let now = Date(timeIntervalSince1970: 1_800_000_000)
      var png = Data([137, 80, 78, 71, 13, 10, 26, 10])
      png.append(Data((0..<200_000).map { UInt8($0 % 251) }))
      let image = ClipboardEntry(
        payload: ClipboardPayload(kind: .image, image: png), copiedAt: now,
        sourceName: "Fixture", sourceBundle: "fixture")
      let text = ClipboardEntry(
        payload: ClipboardPayload(kind: .text, text: "Texto"), copiedAt: now,
        sourceName: "Fixture", sourceBundle: "fixture")
      let temporary = FileManager.default.temporaryDirectory.appendingPathComponent(
        "Sieghart-Clipboard-\(UUID())")
      defer { try? FileManager.default.removeItem(at: temporary) }
      let file = temporary.appendingPathComponent("history.json")
      let media = temporary.appendingPathComponent("media")
      let disk = LocalClipboardStorage(url: file)

      try await disk.save([image, text], revision: 1)
      let indexSize = try #require(
        try FileManager.default.attributesOfItem(atPath: file.path)[.size] as? NSNumber).intValue
      #expect(indexSize < 4_096, "The index carries a reference, not the image bytes")
      let stored = try FileManager.default.contentsOfDirectory(atPath: media.path)
      #expect(stored.count == 1)
      let mediaFile = media.appendingPathComponent(try #require(stored.first))
      let written = try #require(
        try FileManager.default.attributesOfItem(atPath: mediaFile.path)[.modificationDate] as? Date)
      let mediaPermission = try #require(
        try FileManager.default.attributesOfItem(atPath: mediaFile.path)[.posixPermissions] as? NSNumber).intValue
      #expect(mediaPermission == 0o600)
      #expect(try await disk.load() == [image, text])

      var pinned = image; pinned.pinned = true
      try await disk.save([pinned, text], revision: 2)
      let rewritten = try #require(
        try FileManager.default.attributesOfItem(atPath: mediaFile.path)[.modificationDate] as? Date)
      #expect(rewritten == written, "Pinning rewrites the index only, never the image")

      try await disk.save([text], revision: 3)
      #expect(try FileManager.default.contentsOfDirectory(atPath: media.path).isEmpty)
      #expect(try await disk.load() == [text])
    }

    @Test("G12.09 O histórico no formato antigo (imagem dentro do JSON) ainda é lido e migra")
    func legacyFormat() async throws {
      let now = Date(timeIntervalSince1970: 1_800_000_000)
      var png = Data([137, 80, 78, 71, 13, 10, 26, 10]); png.append(Data(repeating: 7, count: 64))
      let legacy = [ClipboardEntry(
        payload: ClipboardPayload(kind: .image, image: png), copiedAt: now,
        sourceName: "Fixture", sourceBundle: "fixture")]
      let temporary = FileManager.default.temporaryDirectory.appendingPathComponent(
        "Sieghart-Clipboard-\(UUID())")
      defer { try? FileManager.default.removeItem(at: temporary) }
      try FileManager.default.createDirectory(at: temporary, withIntermediateDirectories: true)
      let file = temporary.appendingPathComponent("history.json")
      try JSONEncoder().encode(legacy).write(to: file)
      let disk = LocalClipboardStorage(url: file)
      #expect(try await disk.load() == legacy)
      try await disk.save(legacy, revision: 1)
      #expect(try await disk.load() == legacy)
      #expect(try FileManager.default.contentsOfDirectory(atPath: temporary.appendingPathComponent("media").path).count == 1)
    }

  }
}
