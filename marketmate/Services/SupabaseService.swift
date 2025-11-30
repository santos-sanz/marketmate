import Foundation
import Supabase

final class SupabaseService {
  static let shared = SupabaseService()

  let client: SupabaseClient

  private init() {
    self.client = SupabaseClient(
      supabaseURL: URL(string: "https://gqhjlguqwsxozikglcuf.supabase.co")!,
      supabaseKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdxaGpsZ3Vxd3N4b3ppa2dsY3VmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM3NDgzMjIsImV4cCI6MjA3OTMyNDMyMn0.CY6Pt82zV0uWErJAJQCFb6hok-Z2xGC5HkUXYC-_ibg"
    )
  }
}
