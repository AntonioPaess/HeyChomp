import SwiftUI

/// Equipe: os seis agentes com o status de agora.
@MainActor
@Observable
final class TeamViewModel {
    let team: [AgentStatus]

    init(data: any DataSource = MockDataSource()) {
        team = data.teamStatus
    }

    var workingCount: Int { team.filter(\.isWorking).count }
    var summary: String { "\(workingCount) trabalhando agora" }
}
