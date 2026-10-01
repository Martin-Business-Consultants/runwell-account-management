module AccountManagement
  # A client that needs something from a person on their home page (Attention): kind is :quiet,
  # :health or :digest.
  Alert = Data.define(:client, :kind, :detail)
end
