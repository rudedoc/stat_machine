# app/services/firebase_auth_service.rb
class FirebaseAuthService
  # The issuer for Firebase tokens is always this URL + your Project ID
  VALID_ISSUER = "https://securetoken.google.com/ai-score-predict"

  def self.verify(token)
    # This gem automatically handles Google's public key rotation
    payload = FirebaseIdToken::Signature.verify(token)
    return payload # Returns nil if invalid
  end
end
