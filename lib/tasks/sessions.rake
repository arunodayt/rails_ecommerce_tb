namespace :sessions do
  # Removes sessions that can no longer authenticate anyone: expired ones, plus
  # sessions revoked more than the refresh-token lifetime ago (kept briefly so
  # reuse detection still works against recently-rotated tokens).
  #
  # Usage: bin/rails sessions:cleanup
  desc "Delete expired and stale revoked sessions"
  task cleanup: :environment do
    cutoff = JsonWebToken::REFRESH_TTL.ago
    deleted = Session
              .where(expires_at: ..Time.current)
              .or(Session.where(revoked_at: ..cutoff))
              .delete_all
    puts "Deleted #{deleted} stale session(s)"
  end
end
