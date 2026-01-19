-- CreateEnum
CREATE TYPE "Role" AS ENUM ('ADMIN', 'ANALYST', 'VIEWER');

-- CreateEnum
CREATE TYPE "AssetType" AS ENUM ('DOMAIN', 'SUBDOMAIN', 'IP', 'CNAME');

-- CreateEnum
CREATE TYPE "AssetStatus" AS ENUM ('ACTIVE', 'INACTIVE', 'SUSPICIOUS', 'CONFIRMED_MALICIOUS');

-- CreateEnum
CREATE TYPE "ScanType" AS ENUM ('PORT_SCAN', 'SERVICE_DETECT', 'VULN_SCAN', 'JARM_FINGERPRINT');

-- CreateEnum
CREATE TYPE "AttackResultStatus" AS ENUM ('SUCCESS', 'FAILED', 'TIMEOUT', 'ERROR');

-- CreateEnum
CREATE TYPE "IntelSource" AS ENUM ('VIRUSTOTAL', 'URLSCAN', 'CENSYS', 'ABUSEIPDB', 'SHODAN');

-- CreateEnum
CREATE TYPE "TagCategory" AS ENUM ('C2', 'PHISHING', 'MALWARE', 'SUSPICIOUS', 'VERIFIED_CLEAN');

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "password_hash" TEXT NOT NULL,
    "full_name" TEXT,
    "role" "Role" NOT NULL DEFAULT 'VIEWER',
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "last_login_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "assets" (
    "id" TEXT NOT NULL,
    "domain" TEXT NOT NULL,
    "ip_address" TEXT,
    "ip_owner" TEXT,
    "asset_type" "AssetType" NOT NULL DEFAULT 'DOMAIN',
    "status" "AssetStatus" NOT NULL DEFAULT 'ACTIVE',
    "risk_score" DECIMAL(5,2) NOT NULL DEFAULT 0,
    "first_seen_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "last_seen_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "metadata" JSONB,
    "created_by_id" TEXT,

    CONSTRAINT "assets_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "recon_results" (
    "id" TEXT NOT NULL,
    "asset_id" TEXT NOT NULL,
    "scan_type" "ScanType" NOT NULL,
    "port" INTEGER,
    "protocol" TEXT,
    "service" TEXT,
    "version" TEXT,
    "vulnerabilities" JSONB,
    "raw_output" JSONB,
    "scanned_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "recon_results_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "attack_results" (
    "id" TEXT NOT NULL,
    "asset_id" TEXT NOT NULL,
    "recon_id" TEXT,
    "attack_type" TEXT NOT NULL,
    "payload" TEXT,
    "result" "AttackResultStatus" NOT NULL,
    "evidence" JSONB,
    "risk_impact" DECIMAL(5,2),
    "executed_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "attack_results_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "external_intel" (
    "id" TEXT NOT NULL,
    "asset_id" TEXT NOT NULL,
    "source" "IntelSource" NOT NULL,
    "query_hash" TEXT NOT NULL,
    "response_data" JSONB NOT NULL,
    "reputation_score" DECIMAL(5,2),
    "is_malicious" BOOLEAN NOT NULL DEFAULT false,
    "fetched_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expires_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "external_intel_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "risk_tags" (
    "id" TEXT NOT NULL,
    "asset_id" TEXT NOT NULL,
    "tag_name" TEXT NOT NULL,
    "tag_category" "TagCategory" NOT NULL,
    "confidence" DECIMAL(3,2) NOT NULL DEFAULT 0,
    "evidence_ids" TEXT[],
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "risk_tags_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "search_history" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "search_query" TEXT NOT NULL,
    "search_type" TEXT,
    "results_count" INTEGER,
    "filters" JSONB,
    "searched_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "search_history_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE INDEX "assets_domain_idx" ON "assets"("domain");

-- CreateIndex
CREATE INDEX "assets_risk_score_idx" ON "assets"("risk_score" DESC);

-- CreateIndex
CREATE UNIQUE INDEX "assets_domain_ip_address_key" ON "assets"("domain", "ip_address");

-- CreateIndex
CREATE INDEX "recon_results_asset_id_scanned_at_idx" ON "recon_results"("asset_id", "scanned_at");

-- CreateIndex
CREATE INDEX "attack_results_asset_id_executed_at_idx" ON "attack_results"("asset_id", "executed_at");

-- CreateIndex
CREATE INDEX "external_intel_expires_at_idx" ON "external_intel"("expires_at");

-- CreateIndex
CREATE INDEX "external_intel_is_malicious_idx" ON "external_intel"("is_malicious");

-- CreateIndex
CREATE UNIQUE INDEX "external_intel_asset_id_source_query_hash_key" ON "external_intel"("asset_id", "source", "query_hash");

-- CreateIndex
CREATE INDEX "risk_tags_tag_name_idx" ON "risk_tags"("tag_name");

-- CreateIndex
CREATE INDEX "risk_tags_tag_category_idx" ON "risk_tags"("tag_category");

-- CreateIndex
CREATE UNIQUE INDEX "risk_tags_asset_id_tag_name_key" ON "risk_tags"("asset_id", "tag_name");

-- CreateIndex
CREATE INDEX "search_history_user_id_searched_at_idx" ON "search_history"("user_id", "searched_at" DESC);

-- AddForeignKey
ALTER TABLE "assets" ADD CONSTRAINT "assets_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "recon_results" ADD CONSTRAINT "recon_results_asset_id_fkey" FOREIGN KEY ("asset_id") REFERENCES "assets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "attack_results" ADD CONSTRAINT "attack_results_asset_id_fkey" FOREIGN KEY ("asset_id") REFERENCES "assets"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "attack_results" ADD CONSTRAINT "attack_results_recon_id_fkey" FOREIGN KEY ("recon_id") REFERENCES "recon_results"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "external_intel" ADD CONSTRAINT "external_intel_asset_id_fkey" FOREIGN KEY ("asset_id") REFERENCES "assets"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "risk_tags" ADD CONSTRAINT "risk_tags_asset_id_fkey" FOREIGN KEY ("asset_id") REFERENCES "assets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "search_history" ADD CONSTRAINT "search_history_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
