# =======================================================
# 1. Mengambil Sertifikat GitHub Actions OIDC
# =======================================================
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# =======================================================
# 2. Membuat Identity Provider di AWS IAM
# =======================================================
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

# =======================================================
# 3. Membuat IAM Role untuk GitHub Actions
# =======================================================
resource "aws_iam_role" "github_actions" {
  name = "SkyBridge-GitHubActions-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          },
          StringLike = {
            # Pastikan format ini sesuai dengan Repository yang digunakan
            # Format: repo:USERNAME/REPO-NAME:*
            "token.actions.githubusercontent.com:sub" = "repo:stayrelevantid/skybridge-enterprise:*"
          }
        }
      }
    ]
  })
}

# =======================================================
# 4. Attach Policy AdministratorAccess agar bebas deploy
#    Catatan: Bisa diperketat bila untuk produksi nyata.
# =======================================================
resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
