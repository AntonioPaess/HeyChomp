import AppKit
import Foundation
import Testing

extension LogicTests {
  @Suite(.tags(.clipboard, .logic))
  struct CompanionGazeTests {
    @Test("G12.05 gaze tracks both sides and is neutral at center")
    func gaze() throws {
      let width = CGSize(width: 610, height: 220)
      #expect(CompanionGaze.sample(point: CGPoint(x: 0, y: 110), in: width).width == -4)
      #expect(CompanionGaze.sample(point: CGPoint(x: 610, y: 110), in: width).width == 4)
      #expect(CompanionGaze.sample(point: CGPoint(x: 305, y: 110), in: width) == .zero)
    }

    @Test("G12.08 screen-wide gaze follows the pointer, clamps, and looks down below the character")
    func screenGaze() throws {
      let center = CGPoint(x: 800, y: 900)
      #expect(CompanionGaze.screen(pointer: center, center: center) == .zero)
      #expect(CompanionGaze.screen(pointer: CGPoint(x: 0, y: 900), center: center).width == -4)
      #expect(CompanionGaze.screen(pointer: CGPoint(x: 1600, y: 900), center: center).width == 4)
      // AppKit screen y grows upward: a pointer below the character is a downward look.
      #expect(CompanionGaze.screen(pointer: CGPoint(x: 800, y: 0), center: center).height == 3)
      #expect(CompanionGaze.screen(pointer: CGPoint(x: 930, y: 900), center: center).width == 2)
    }

    @Test("G12.09 gaze eases toward its target and settles at exactly zero")
    func smoothedGaze() throws {
      let step = CompanionGaze.smoothed(.zero, toward: CGSize(width: 4, height: 0))
      #expect(step.width > 0 && step.width < 4)
      var resting = CGSize(width: 3, height: -2)
      for _ in 0..<60 { resting = CompanionGaze.smoothed(resting, toward: .zero) }
      #expect(resting == .zero)
    }

    @Test("G12.10 the sparkle sits below-right of the pointer, flips at the right edge and steps aside under the island")
    func cursorCompanionPlacement() throws {
      let screen = CGRect(x: 0, y: 0, width: 1512, height: 982)
      let size = CursorCompanionLayout.size, gap = CursorCompanionLayout.gap
      let middle = CursorCompanionLayout.origin(pointer: CGPoint(x: 700, y: 500), screen: screen)
      #expect(!middle.onLeft)
      #expect(middle.origin == CGPoint(x: 700 + gap.width, y: 500 - gap.height - size))
      let edge = CursorCompanionLayout.origin(pointer: CGPoint(x: 1500, y: 500), screen: screen)
      #expect(edge.onLeft && edge.origin.x + size <= 1500)
      let bottom = CursorCompanionLayout.origin(pointer: CGPoint(x: 700, y: 20), screen: screen)
      #expect(bottom.origin.y >= 20)
      #expect(CursorCompanionLayout.hidesNearIsland(pointer: CGPoint(x: 756, y: 970), screen: screen))
      #expect(!CursorCompanionLayout.hidesNearIsland(pointer: CGPoint(x: 756, y: 500), screen: screen))
      let step = CursorCompanionLayout.follow(.zero, toward: CGPoint(x: 100, y: 0))
      #expect(step.x > 0 && step.x < 100)
    }

  }
}
