-- =====================================================================
--  DATABASE: Buku Kas Reuni Alumni SMP 66 Angkatan 1996
--  Deskripsi : Skema database untuk aplikasi pencatatan pembayaran
--              peserta reuni, lengkap dengan tabel user login (Admin &
--              User biasa) dan log aktivitas (audit trail).
--  Kompatibel: MySQL 5.7+ / MariaDB 10.2+ (cocok untuk XAMPP/phpMyAdmin)
-- =====================================================================

CREATE DATABASE IF NOT EXISTS db_alumni_smp66
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE db_alumni_smp66;

-- ---------------------------------------------------------------------
-- Tabel: users
-- Menyimpan akun login. role menentukan hak akses:
--   - admin : boleh input, edit, update, hapus data peserta
--   - user  : hanya boleh melihat data (read-only)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  username      VARCHAR(50)  NOT NULL UNIQUE,
  password      VARCHAR(255) NOT NULL,               -- simpan HASH password, jangan plain text (lihat catatan di bawah)
  role          ENUM('admin','user') NOT NULL DEFAULT 'user',
  created_at    DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- Tabel: peserta
-- Data utama pembayaran peserta reuni.
-- attachment_path menyimpan lokasi file bukti pembayaran yang diunggah
-- ke server (folder uploads/), bukan file-nya langsung, agar database
-- tetap ringan.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS peserta (
  id                  INT AUTO_INCREMENT PRIMARY KEY,
  nama_alumni         VARCHAR(150) NOT NULL,
  nama_pengirim       VARCHAR(150),
  tgl_transaksi       DATE,
  tgl_kirim_wag       DATE,
  no_transaksi        VARCHAR(100),
  total_pembayaran    DECIMAL(15,2) DEFAULT 0,
  total_peserta       INT DEFAULT 1,
  attachment_path     VARCHAR(255),                  -- contoh: uploads/2026/07/bukti_123.jpg
  attachment_name     VARCHAR(255),                  -- nama file asli saat diunggah
  created_by          VARCHAR(50),                   -- username yang menginput data
  updated_by          VARCHAR(50),                   -- username yang terakhir mengubah data
  created_at          DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at          DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_peserta_created_by
    FOREIGN KEY (created_by) REFERENCES users(username)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_peserta_updated_by
    FOREIGN KEY (updated_by) REFERENCES users(username)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Index untuk mempercepat pencarian & pengurutan
CREATE INDEX idx_peserta_nama       ON peserta (nama_alumni);
CREATE INDEX idx_peserta_no_trx     ON peserta (no_transaksi);
CREATE INDEX idx_peserta_tgl_trx    ON peserta (tgl_transaksi);

-- ---------------------------------------------------------------------
-- Tabel: activity_log
-- Mencatat siapa melakukan apa (Tambah / Update / Hapus) dan kapan,
-- untuk kebutuhan audit / riwayat aktivitas.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS activity_log (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  ts            DATETIME DEFAULT CURRENT_TIMESTAMP,
  username      VARCHAR(50),
  action        ENUM('Tambah','Update','Hapus') NOT NULL,
  nama_alumni   VARCHAR(150),
  detail        TEXT,
  FOREIGN KEY (username) REFERENCES users(username)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_log_ts ON activity_log (ts);

-- ---------------------------------------------------------------------
-- Seed data: akun login awal
-- PENTING: password di bawah ini PLAIN TEXT hanya untuk contoh/testing.
-- Untuk aplikasi produksi, ganti dengan hash, misalnya di PHP:
--   password_hash('admin123', PASSWORD_BCRYPT)
-- lalu saat login gunakan password_verify().
-- ---------------------------------------------------------------------
INSERT INTO users (username, password, role) VALUES
  ('admin',  'admin123',  'admin'),
  ('alumni', 'alumni123', 'user');

-- ---------------------------------------------------------------------
-- Contoh data peserta (opsional, hapus/komentari jika tidak diperlukan)
-- ---------------------------------------------------------------------
INSERT INTO peserta
  (nama_alumni, nama_pengirim, tgl_transaksi, tgl_kirim_wag, no_transaksi,
   total_pembayaran, total_peserta, attachment_path, attachment_name,
   created_by, updated_by)
VALUES
  ('Contoh Nama Alumni', 'Contoh Nama Pengirim', '2026-07-01', '2026-07-01',
   'TRX-0001', 150000, 1, NULL, NULL, 'admin', 'admin');

INSERT INTO activity_log (username, action, nama_alumni, detail) VALUES
  ('admin', 'Tambah', 'Contoh Nama Alumni', 'Total bayar Rp 150.000');
