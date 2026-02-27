# Project SkyBridge Enterprise

SkyBridge Enterprise adalah proyek infrastruktur as code (IaC) menggunakan Terraform yang mendemonstrasikan pembangunan arsitektur *3-Tier* yang sangat tersedia (Highly Available) dan aman (Secure) di Amazon Web Services (AWS), digabungkan dengan alur CI/CD otomatis menggunakan GitHub Actions.

## 🏗 Arsitektur Sistem

Proyek ini membangun arsitektur standar *enterprise* yang terdiri dari:

- **VPC 3-Tier Network (Multi-AZ)**:
  - **Public Tier**: Menampung Application Load Balancer (ALB) dan NAT Gateway.
  - **Private App Tier**: Menampung Auto Scaling Group (ASG) dan instance EC2 (menjalankan web server Nginx).
  - **Private Data Tier**: Disiapkan untuk isolasi Database di masa mendatang.
- **Compute & Scaling**: 
  - Application Load Balancer (ALB) sebagai satu-satunya pintu masuk traffic publik.
  - Auto Scaling Group (ASG) dengan Health Check yang terintegrasi ke ALB.
  - Mendukung *Zero-Downtime Deployment* melalui fitur ASG *Instance Refresh*.
- **Security**: 
  - Security Group untuk secara ketat membatasi akses (hanya mengizinkan trafik HTTP/HTTPS ke ALB, dan trafik dari ALB ke EC2).
- **Backend & State Management**: 
  - Terraform state disimpan secara remote di Amazon S3 dengan *State Locking* menggunakan DynamoDB.

## 🚀 CI/CD Pipeline (GitHub Actions)

Proyek ini mengimplementasikan CI/CD secara penuh:

1. **Authentication**: Menggunakan AWS OIDC provider untuk otentikasi *keyless* yang aman antara GitHub Actions dan AWS.
2. **CI (Audit)**: Saat *Pull Request* baru dibuat, GitHub Actions menjalankan `terraform fmt`, `terraform validate`, dan `terraform plan`, lalu menampilkan hasil perencanaannya langsung pada komentar PR.
3. **CD (Deploy)**: Saat PR di-*merge* ke *branch* utama (`main`), `terraform apply` dijalankan secara otomatis untuk mendeploy perubahan infrastruktur.

## 📂 Struktur Direktori

```text
skybridge-enterprise/
├── bootstrap/            # Konfigurasi pendukung awal (S3 & DynamoDB backend)
├── .github/workflows/    # Definisi pipeline CI/CD GitHub Actions
├── locals.tf             # Variabel lokal dan standardisasi tagging AWS
├── provider.tf           # Konfigurasi AWS Provider
├── backend.tf            # Konfigurasi Remote State menggunakan S3 & DynamoDB
├── oidc.tf               # Konfigurasi AWS IAM OIDC Provider untuk GitHub Actions
├── vpc.tf                # Modul definisi Jaringan (VPC, Subnet, NAT, IGW)
├── security.tf           # Modul definisi Security Groups
├── compute.tf            # Modul definisi ALB dan Auto Scaling Group (ASG)
└── blueprint.md          # Dokumen arsitektur rinci & fase eksekusi
```

## 🛠 Prasyarat

Sebelum mengeksekusi secara lokal, pastikan tools berikut sudah terinstal di sistem Anda:

- [Terraform](https://developer.hashicorp.com/terraform/downloads) (v1.5.0+)
- [AWS CLI](https://aws.amazon.com/cli/) dikonfigurasi dengan kredensial Administrator.
- Git.

## ⚙️ Petunjuk Eksekusi Manual (Local)

Walaupun proyek ini dirancang untuk dijalankan melalui GitHub Actions, Anda dapat mengeksekusinya secara lokal untuk keperluan testing:

1. **Inisialisasi Terraform**:
   ```bash
   terraform init
   ```
2. **Review Rencana Infrastruktur**:
   ```bash
   terraform plan
   ```
3. **Deploy Infrastruktur**:
   ```bash
   terraform apply
   ```
4. **Update & Redeploy Aplikasi (Opsional)**:
   - Apabila ada perubahan skrip pada *Launch Template* (misal: mengganti versi Nginx), cukup jalankan kembali `terraform apply`.
   - Terraform akan memicu penugasan **ASG Instance Refresh** untuk menggantikan mesin lama dengan berhati-hati tanpa *downtime*.
5. **Membersihkan Infrastruktur (Self-Destruct)**:
   ```bash
   terraform destroy -auto-approve
   ```
   *Catatan: Sangat disarankan untuk segera menghapus semua resource AWS setelah selesai melakukan eksplorasi untuk menghindari tagihan.*

## 🏷️ Standardisasi Audit

Semua sumber daya yang dibuat melalui proyek ini menggunakan *Common Tags* yang dikelola pada `locals.tf` untuk memudahkan audit dan pemantauan biaya, termasuk penanda khusus `DeletionPriority = "High"` untuk pembersihan infrastruktur lab.
