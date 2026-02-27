# Project SkyBridge Enterprise - Final Blueprint

Ini adalah finalisasi menyeluruh untuk Project SkyBridge. Kita akan menggabungkan arsitektur VPC 3-Tier, ASG, ALB, serta kebijakan Audit dan Manual Destroy ke dalam satu blueprint siap pakai.

## 1. Blueprint Final: Arsitektur Sistem

### Arsitektur Infrastruktur (AWS)
- **VPC 3-Tier**:
  - **Public Tier**: 2 Subnet (ALB + NAT Gateway).
  - **Private App Tier**: 2 Subnet (ASG + EC2 Nginx).
  - **Private Data Tier**: 2 Subnet (Isolasi Database).
- **Traffic Management**: Application Load Balancer (ALB) sebagai pintu utama.
- **Compute & Scaling**: Auto Scaling Group (ASG) dengan Health Check terintegrasi ke ALB.
- **Audit Layer**: Resource tagging otomatis di seluruh komponen.

### Arsitektur Workflow (GitHub Actions)
- **CI (Audit)**: Trigger saat *Pull Request*. Menjalankan `terraform plan` dan posting hasil ke komentar PR.
- **CD (Deploy)**: Trigger saat *Merge* ke `main`. Menjalankan `terraform apply`.
- **Manual (Destroy)**: Eksekusi `terraform destroy` secara lokal dari komputer untuk menghapus seluruh *resource* termasuk S3 Bucket State.

## 2. Struktur Kode & Labeling Audit

File: `locals.tf` (Ini adalah jantung dari Labeling Audit kamu).

```hcl
locals {
  project_name = "SkyBridge-Enterprise"
  owner        = "stayrelevantid"
  environment  = "Production-Lab"

  common_tags = {
    Project           = local.project_name
    Owner             = local.owner
    Environment       = local.environment
    ManagedBy         = "Terraform"
    CostCenter        = "DevOps-Learning"
    DeletionPriority  = "High" # Penanda untuk audit pembersihan
  }
}
```
> **Catatan:** Gunakan `tags = local.common_tags` di setiap resource AWS kamu.

## 3. Struktur Direktori Proyek

Agar rapi dan mudah di-_maintain_, kita akan menggunakan struktur folder berikut:

```text
skybridge-enterprise/
├── bootstrap/            # Fase 1: S3 & DynamoDB untuk State Locking
│   └── main.tf
├── .github/workflows/    # CI/CD GitHub Actions
│   ├── audit.yml
│   ├── deploy.yml
│   └── destroy.yml
├── locals.tf             # Variabel lokal & Tagging Audit
├── provider.tf           # Konfigurasi AWS Provider
├── backend.tf            # Konfigurasi Remote State S3
├── oidc.tf               # Konfigurasi GitHub OIDC
├── vpc.tf                # Fase 2: Network Module
├── security.tf           # Fase 3: Security Groups Module
├── compute.tf            # Fase 3: ALB & ASG Module
└── .gitignore
```

## 4. Fase Eksekusi: Roadmap Strategis

### Fase 1: Inisialisasi Security & Backend
- **AWS OIDC Setup**: Buat Identity Provider di IAM untuk GitHub Actions (Keyless).
- **State Locking**: Buat S3 Bucket dan DynamoDB untuk menyimpan state Terraform.
- **Local Setup**: Siapkan folder proyek dan file `provider.tf`.

### Fase 2: Pembangunan Jaringan (3-Tier)
> **Catatan**: Gunakan Official AWS Terraform Module (`terraform-aws-modules/vpc/aws`).
- **VPC & Subnets**: Definisikan 6 subnet di 2 Availability Zone (AZ) berbeda melalu konfigurasi modul.
- **Routing**:
  - **Public Subnet**: Terhubung ke Internet Gateway (Via modul).
  - **Private Subnet**: Terhubung ke internet via NAT Gateway (hanya untuk download package Nginx).
- **PR Policy**: Lakukan push ke branch baru, buat Pull Request, dan review hasil `terraform plan` di kolom komentar GitHub.

### Fase 3: Deployment Traffic & Compute
> **Catatan**: Gunakan Official AWS Terraform Module untuk ALB (`terraform-aws-modules/alb/aws`) dan ASG (`terraform-aws-modules/autoscaling/aws`).
- **Security Group Audit**:
  - **ALB SG**: Buka port 80 untuk dunia.
  - **EC2 SG**: Buka port 80 hanya dari ALB SG.
- **ASG & Nginx**: Konfigurasi Launch Template dengan script Nginx dan hubungkan ke ASG.
- **Merge to Main**: Lakukan merge untuk memicu deployment otomatis.

### Fase 4: Operasional & Testing
- **Verifikasi URL**: Akses DNS Name dari Load Balancer di browser.
- **Tag Audit**: Cek AWS Tag Editor untuk memastikan semua resource memiliki tag `Owner: stayrelevantid`.
- **High Availability Test**: Coba terminate satu instance di console dan lihat ASG membuat penggantinya secara otomatis.

### Fase 5: Clean Self-Destruct (Manual)
- **Local Local Destroy**: Saat lab selesai, buka terminal di folder Terraform kamu.
- **Eksekusi**: Jalankan perintah `terraform destroy --auto-approve` secara lokal.
- **Verification**: Pastikan semua *resource* termasuk VPC, EC2, ALB, serta S3 Bucket dan DynamoDB yang menyimpan state telah terhapus sempurna dari AWS Console.

## 5. Checklist Keamanan Sebelum Mulai

- [ ] Pastikan Role AWS CLI atau user lokal kamu memiliki izin yang cukup (Administrator Access) untuk mengeksekusi `terraform destroy`.
- [ ] Gunakan `.gitignore` untuk file `.terraform`, `*.tfstate`, dan `terraform.tfvars`.
- [ ] Cek kuota AWS (terutama NAT Gateway) karena ini adalah resource yang berbayar per jam.