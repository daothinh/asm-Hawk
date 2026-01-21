-- CreateEnum
CREATE TYPE "ReconToolType" AS ENUM ('SUBFINDER', 'HTTPX', 'NUCLEI', 'KATANA', 'DNSX', 'FFUF', 'GOSPIDER', 'WAYBACKURLS', 'SHUFFLEDNS', 'CEWL', 'ASSETFINDER', 'METABIGOR', 'SUBLIST3R', 'SUBDOMAINIZER', 'GITHUB_RECON', 'CLOUD_ENUM', 'LINKFINDER');

-- CreateEnum
CREATE TYPE "ScanJobStatus" AS ENUM ('PENDING', 'RUNNING', 'COMPLETED', 'FAILED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "ScopeTargetType" AS ENUM ('COMPANY', 'WILDCARD', 'URL');

-- CreateEnum
CREATE TYPE "ScopeMode" AS ENUM ('PASSIVE', 'ACTIVE');

-- CreateEnum
CREATE TYPE "SearchPermissionType" AS ENUM ('ALL_SCOPES', 'ASSIGNED_SCOPES', 'READ_ONLY', 'CUSTOM');

-- CreateEnum
CREATE TYPE "AttackSurfaceAssetType" AS ENUM ('asn', 'network_range', 'ip_address', 'live_web_server', 'cloud_asset', 'fqdn');

-- CreateTable
CREATE TABLE "scans" (
    "id" TEXT NOT NULL,
    "asset_id" TEXT NOT NULL,
    "tool_type" "ReconToolType" NOT NULL,
    "status" "ScanJobStatus" NOT NULL DEFAULT 'PENDING',
    "command" TEXT,
    "stdout" TEXT,
    "stderr" TEXT,
    "execution_time" TEXT,
    "started_at" TIMESTAMP(3),
    "completed_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "scans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "scan_results" (
    "id" TEXT NOT NULL,
    "scan_id" TEXT NOT NULL,
    "result_type" TEXT NOT NULL,
    "data" JSONB NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "scan_results_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "scan_settings" (
    "id" INTEGER NOT NULL DEFAULT 1,
    "subfinder_rate_limit" INTEGER NOT NULL DEFAULT 20,
    "httpx_rate_limit" INTEGER NOT NULL DEFAULT 150,
    "nuclei_rate_limit" INTEGER NOT NULL DEFAULT 100,
    "katana_rate_limit" INTEGER NOT NULL DEFAULT 50,
    "dnsx_rate_limit" INTEGER NOT NULL DEFAULT 100,
    "ffuf_rate_limit" INTEGER NOT NULL DEFAULT 100,
    "gospider_rate_limit" INTEGER NOT NULL DEFAULT 5,
    "shuffledns_rate_limit" INTEGER NOT NULL DEFAULT 10000,
    "custom_user_agent" TEXT,
    "custom_header" TEXT,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "scan_settings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "scope_targets" (
    "id" TEXT NOT NULL,
    "type" "ScopeTargetType" NOT NULL,
    "mode" "ScopeMode" NOT NULL DEFAULT 'PASSIVE',
    "scope_target" TEXT NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "scope_targets_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "auto_scan_sessions" (
    "id" TEXT NOT NULL,
    "scope_target_id" TEXT NOT NULL,
    "config_snapshot" JSONB NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "started_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "ended_at" TIMESTAMP(3),
    "steps_run" JSONB,
    "error_message" TEXT,
    "final_consolidated_subdomains" INTEGER,
    "final_live_web_servers" INTEGER,

    CONSTRAINT "auto_scan_sessions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "target_urls" (
    "id" TEXT NOT NULL,
    "url" TEXT NOT NULL,
    "screenshot" TEXT,
    "status_code" INTEGER,
    "title" TEXT,
    "web_server" TEXT,
    "technologies" TEXT[],
    "content_length" INTEGER,
    "newly_discovered" BOOLEAN NOT NULL DEFAULT false,
    "no_longer_live" BOOLEAN NOT NULL DEFAULT false,
    "scope_target_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "has_deprecated_tls" BOOLEAN NOT NULL DEFAULT false,
    "has_expired_ssl" BOOLEAN NOT NULL DEFAULT false,
    "has_mismatched_ssl" BOOLEAN NOT NULL DEFAULT false,
    "has_self_signed_ssl" BOOLEAN NOT NULL DEFAULT false,
    "findings_json" JSONB,
    "http_response_headers" JSONB,
    "katana_results" JSONB,
    "ffuf_results" JSONB,
    "roi_score" INTEGER NOT NULL DEFAULT 50,
    "ip_address" TEXT,

    CONSTRAINT "target_urls_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_search_permissions" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "permission_type" "SearchPermissionType" NOT NULL DEFAULT 'ASSIGNED_SCOPES',
    "can_run_scans" BOOLEAN NOT NULL DEFAULT false,
    "can_export_data" BOOLEAN NOT NULL DEFAULT false,
    "can_view_sensitive" BOOLEAN NOT NULL DEFAULT false,
    "max_scans_per_day" INTEGER NOT NULL DEFAULT 10,
    "search_rules" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "user_search_permissions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_scope_access" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "scope_target_id" TEXT NOT NULL,
    "can_read" BOOLEAN NOT NULL DEFAULT true,
    "can_write" BOOLEAN NOT NULL DEFAULT false,
    "can_run_scans" BOOLEAN NOT NULL DEFAULT false,
    "can_delete" BOOLEAN NOT NULL DEFAULT false,
    "granted_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "granted_by_id" TEXT,

    CONSTRAINT "user_scope_access_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_settings" (
    "id" TEXT NOT NULL,
    "amass_rate_limit" INTEGER NOT NULL DEFAULT 10,
    "httpx_rate_limit" INTEGER NOT NULL DEFAULT 150,
    "subfinder_rate_limit" INTEGER NOT NULL DEFAULT 20,
    "gau_rate_limit" INTEGER NOT NULL DEFAULT 10,
    "sublist3r_rate_limit" INTEGER NOT NULL DEFAULT 10,
    "ctl_rate_limit" INTEGER NOT NULL DEFAULT 10,
    "shuffledns_rate_limit" INTEGER NOT NULL DEFAULT 10000,
    "cewl_rate_limit" INTEGER NOT NULL DEFAULT 10,
    "gospider_rate_limit" INTEGER NOT NULL DEFAULT 5,
    "subdomainizer_rate_limit" INTEGER NOT NULL DEFAULT 5,
    "nuclei_screenshot_rate_limit" INTEGER NOT NULL DEFAULT 20,
    "custom_user_agent" TEXT,
    "custom_header" TEXT,
    "burp_proxy_ip" TEXT NOT NULL DEFAULT '127.0.0.1',
    "burp_proxy_port" INTEGER NOT NULL DEFAULT 8080,
    "burp_api_ip" TEXT NOT NULL DEFAULT '127.0.0.1',
    "burp_api_port" INTEGER NOT NULL DEFAULT 1337,
    "burp_api_key" TEXT NOT NULL DEFAULT '',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_settings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "api_keys" (
    "id" TEXT NOT NULL,
    "tool_name" TEXT NOT NULL,
    "api_key_name" TEXT NOT NULL,
    "api_key_value" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "api_keys_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ai_api_keys" (
    "id" TEXT NOT NULL,
    "provider" TEXT NOT NULL,
    "api_key_name" TEXT NOT NULL,
    "key_values" JSONB NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ai_api_keys_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "auto_scan_config" (
    "id" TEXT NOT NULL,
    "amass" BOOLEAN NOT NULL DEFAULT true,
    "sublist3r" BOOLEAN NOT NULL DEFAULT true,
    "assetfinder" BOOLEAN NOT NULL DEFAULT true,
    "gau" BOOLEAN NOT NULL DEFAULT true,
    "ctl" BOOLEAN NOT NULL DEFAULT true,
    "subfinder" BOOLEAN NOT NULL DEFAULT true,
    "consolidate_httpx_round1" BOOLEAN NOT NULL DEFAULT true,
    "shuffledns" BOOLEAN NOT NULL DEFAULT true,
    "cewl" BOOLEAN NOT NULL DEFAULT true,
    "consolidate_httpx_round2" BOOLEAN NOT NULL DEFAULT true,
    "gospider" BOOLEAN NOT NULL DEFAULT true,
    "subdomainizer" BOOLEAN NOT NULL DEFAULT true,
    "consolidate_httpx_round3" BOOLEAN NOT NULL DEFAULT true,
    "nuclei_screenshot" BOOLEAN NOT NULL DEFAULT true,
    "metadata" BOOLEAN NOT NULL DEFAULT true,
    "max_consolidated_subdomains" INTEGER NOT NULL DEFAULT 2500,
    "max_live_web_servers" INTEGER NOT NULL DEFAULT 500,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "auto_scan_config_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "auto_scan_state" (
    "id" TEXT NOT NULL,
    "scope_target_id" TEXT NOT NULL,
    "current_step" TEXT NOT NULL,
    "is_paused" BOOLEAN NOT NULL DEFAULT false,
    "is_cancelled" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "auto_scan_state_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "amass_scans" (
    "id" TEXT NOT NULL,
    "scan_id" TEXT NOT NULL,
    "domain" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "result" TEXT,
    "error" TEXT,
    "stdout" TEXT,
    "stderr" TEXT,
    "command" TEXT,
    "execution_time" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "scope_target_id" TEXT,
    "auto_scan_session_id" TEXT,

    CONSTRAINT "amass_scans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "amass_intel_scans" (
    "id" TEXT NOT NULL,
    "scan_id" TEXT NOT NULL,
    "company_name" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "result" TEXT,
    "error" TEXT,
    "stdout" TEXT,
    "stderr" TEXT,
    "command" TEXT,
    "execution_time" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "scope_target_id" TEXT,
    "auto_scan_session_id" TEXT,

    CONSTRAINT "amass_intel_scans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "httpx_scans" (
    "id" TEXT NOT NULL,
    "scan_id" TEXT NOT NULL,
    "domain" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "result" TEXT,
    "error" TEXT,
    "stdout" TEXT,
    "stderr" TEXT,
    "command" TEXT,
    "execution_time" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "scope_target_id" TEXT,
    "auto_scan_session_id" TEXT,

    CONSTRAINT "httpx_scans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "gau_scans" (
    "id" TEXT NOT NULL,
    "scan_id" TEXT NOT NULL,
    "domain" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "result" TEXT,
    "error" TEXT,
    "stdout" TEXT,
    "stderr" TEXT,
    "command" TEXT,
    "execution_time" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "scope_target_id" TEXT,
    "auto_scan_session_id" TEXT,

    CONSTRAINT "gau_scans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sublist3r_scans" (
    "id" TEXT NOT NULL,
    "scan_id" TEXT NOT NULL,
    "domain" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "result" TEXT,
    "error" TEXT,
    "stdout" TEXT,
    "stderr" TEXT,
    "command" TEXT,
    "execution_time" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "scope_target_id" TEXT,
    "auto_scan_session_id" TEXT,

    CONSTRAINT "sublist3r_scans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "assetfinder_scans" (
    "id" TEXT NOT NULL,
    "scan_id" TEXT NOT NULL,
    "domain" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "result" TEXT,
    "error" TEXT,
    "stdout" TEXT,
    "stderr" TEXT,
    "command" TEXT,
    "execution_time" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "scope_target_id" TEXT,
    "auto_scan_session_id" TEXT,

    CONSTRAINT "assetfinder_scans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ctl_scans" (
    "id" TEXT NOT NULL,
    "scan_id" TEXT NOT NULL,
    "domain" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "result" TEXT,
    "error" TEXT,
    "stdout" TEXT,
    "stderr" TEXT,
    "command" TEXT,
    "execution_time" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "scope_target_id" TEXT,
    "auto_scan_session_id" TEXT,

    CONSTRAINT "ctl_scans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "subfinder_scans" (
    "id" TEXT NOT NULL,
    "scan_id" TEXT NOT NULL,
    "domain" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "result" TEXT,
    "error" TEXT,
    "stdout" TEXT,
    "stderr" TEXT,
    "command" TEXT,
    "execution_time" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "scope_target_id" TEXT,
    "auto_scan_session_id" TEXT,

    CONSTRAINT "subfinder_scans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "shuffledns_scans" (
    "id" TEXT NOT NULL,
    "scan_id" TEXT NOT NULL,
    "domain" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "result" TEXT,
    "error" TEXT,
    "stdout" TEXT,
    "stderr" TEXT,
    "command" TEXT,
    "execution_time" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "scope_target_id" TEXT,
    "auto_scan_session_id" TEXT,

    CONSTRAINT "shuffledns_scans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "cewl_scans" (
    "id" TEXT NOT NULL,
    "scan_id" TEXT NOT NULL,
    "url" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "result" TEXT,
    "error" TEXT,
    "stdout" TEXT,
    "stderr" TEXT,
    "command" TEXT,
    "execution_time" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "scope_target_id" TEXT,
    "auto_scan_session_id" TEXT,

    CONSTRAINT "cewl_scans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "gospider_scans" (
    "id" TEXT NOT NULL,
    "scan_id" TEXT NOT NULL,
    "domain" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "result" TEXT,
    "error" TEXT,
    "stdout" TEXT,
    "stderr" TEXT,
    "command" TEXT,
    "execution_time" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "scope_target_id" TEXT,
    "auto_scan_session_id" TEXT,

    CONSTRAINT "gospider_scans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "subdomainizer_scans" (
    "id" TEXT NOT NULL,
    "scan_id" TEXT NOT NULL,
    "domain" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "result" TEXT,
    "error" TEXT,
    "stdout" TEXT,
    "stderr" TEXT,
    "command" TEXT,
    "execution_time" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "scope_target_id" TEXT,
    "auto_scan_session_id" TEXT,

    CONSTRAINT "subdomainizer_scans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "nuclei_screenshots" (
    "id" TEXT NOT NULL,
    "scan_id" TEXT NOT NULL,
    "domain" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "result" TEXT,
    "error" TEXT,
    "stdout" TEXT,
    "stderr" TEXT,
    "command" TEXT,
    "execution_time" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "scope_target_id" TEXT,
    "auto_scan_session_id" TEXT,

    CONSTRAINT "nuclei_screenshots_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "metadata_scans" (
    "id" TEXT NOT NULL,
    "scan_id" TEXT NOT NULL,
    "domain" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "result" TEXT,
    "error" TEXT,
    "stdout" TEXT,
    "stderr" TEXT,
    "command" TEXT,
    "execution_time" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "scope_target_id" TEXT,
    "auto_scan_session_id" TEXT,
    "config" JSONB,

    CONSTRAINT "metadata_scans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "cloud_enum_scans" (
    "id" TEXT NOT NULL,
    "scan_id" TEXT NOT NULL,
    "company_name" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "result" TEXT,
    "error" TEXT,
    "stdout" TEXT,
    "stderr" TEXT,
    "command" TEXT,
    "execution_time" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "scope_target_id" TEXT,
    "auto_scan_session_id" TEXT,

    CONSTRAINT "cloud_enum_scans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "metabigor_company_scans" (
    "id" TEXT NOT NULL,
    "scan_id" TEXT NOT NULL,
    "company_name" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "result" TEXT,
    "error" TEXT,
    "stdout" TEXT,
    "stderr" TEXT,
    "command" TEXT,
    "execution_time" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "scope_target_id" TEXT,
    "auto_scan_session_id" TEXT,

    CONSTRAINT "metabigor_company_scans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "github_recon_scans" (
    "id" TEXT NOT NULL,
    "scan_id" TEXT NOT NULL,
    "company_name" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "result" TEXT,
    "error" TEXT,
    "stdout" TEXT,
    "stderr" TEXT,
    "command" TEXT,
    "execution_time" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "scope_target_id" TEXT,
    "auto_scan_session_id" TEXT,

    CONSTRAINT "github_recon_scans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "shodan_company_scans" (
    "id" TEXT NOT NULL,
    "scan_id" TEXT NOT NULL,
    "company_name" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "result" TEXT,
    "error" TEXT,
    "stdout" TEXT,
    "stderr" TEXT,
    "command" TEXT,
    "execution_time" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "scope_target_id" TEXT,
    "auto_scan_session_id" TEXT,

    CONSTRAINT "shodan_company_scans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "censys_company_scans" (
    "id" TEXT NOT NULL,
    "scan_id" TEXT NOT NULL,
    "company_name" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "result" TEXT,
    "error" TEXT,
    "stdout" TEXT,
    "stderr" TEXT,
    "command" TEXT,
    "execution_time" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "scope_target_id" TEXT,
    "auto_scan_session_id" TEXT,

    CONSTRAINT "censys_company_scans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "securitytrails_company_scans" (
    "id" TEXT NOT NULL,
    "scan_id" TEXT NOT NULL,
    "company_name" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "result" TEXT,
    "error" TEXT,
    "stdout" TEXT,
    "stderr" TEXT,
    "command" TEXT,
    "execution_time" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "scope_target_id" TEXT,
    "auto_scan_session_id" TEXT,

    CONSTRAINT "securitytrails_company_scans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ip_port_scans" (
    "id" TEXT NOT NULL,
    "scan_id" TEXT NOT NULL,
    "scope_target_id" TEXT,
    "status" TEXT NOT NULL,
    "total_network_ranges" INTEGER NOT NULL DEFAULT 0,
    "processed_network_ranges" INTEGER NOT NULL DEFAULT 0,
    "total_ips_discovered" INTEGER NOT NULL DEFAULT 0,
    "total_ports_scanned" INTEGER NOT NULL DEFAULT 0,
    "live_web_servers_found" INTEGER NOT NULL DEFAULT 0,
    "error_message" TEXT,
    "command" TEXT,
    "execution_time" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "auto_scan_session_id" TEXT,

    CONSTRAINT "ip_port_scans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "discovered_live_ips" (
    "id" TEXT NOT NULL,
    "scan_id" TEXT NOT NULL,
    "ip_address" TEXT NOT NULL,
    "hostname" TEXT,
    "network_range" TEXT NOT NULL,
    "ping_time_ms" DOUBLE PRECISION,
    "discovered_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "discovered_live_ips_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "live_web_servers" (
    "id" TEXT NOT NULL,
    "scan_id" TEXT NOT NULL,
    "ip_address" TEXT NOT NULL,
    "hostname" TEXT,
    "port" INTEGER NOT NULL,
    "protocol" TEXT NOT NULL,
    "url" TEXT NOT NULL,
    "status_code" INTEGER,
    "title" TEXT,
    "server_header" TEXT,
    "content_length" BIGINT,
    "technologies" JSONB,
    "response_time_ms" DOUBLE PRECISION,
    "screenshot_path" TEXT,
    "ssl_info" JSONB,
    "http_response_headers" JSONB,
    "findings_json" JSONB,
    "last_checked" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "live_web_servers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "nuclei_scans" (
    "id" TEXT NOT NULL,
    "scan_id" TEXT NOT NULL,
    "scope_target_id" TEXT NOT NULL,
    "targets" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "templates" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "status" TEXT NOT NULL DEFAULT 'pending',
    "result" TEXT,
    "error" TEXT,
    "stdout" TEXT,
    "stderr" TEXT,
    "command" TEXT,
    "execution_time" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "auto_scan_session_id" TEXT,

    CONSTRAINT "nuclei_scans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "nuclei_configs" (
    "id" TEXT NOT NULL,
    "scope_target_id" TEXT NOT NULL,
    "targets" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "templates" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "severities" TEXT[] DEFAULT ARRAY['critical', 'high', 'medium', 'low', 'info']::TEXT[],
    "uploaded_templates" JSONB NOT NULL DEFAULT '[]',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "nuclei_configs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "katana_url_scans" (
    "id" TEXT NOT NULL,
    "scan_id" TEXT NOT NULL,
    "url" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "result" TEXT,
    "error" TEXT,
    "stdout" TEXT,
    "stderr" TEXT,
    "command" TEXT,
    "execution_time" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "scope_target_id" TEXT,

    CONSTRAINT "katana_url_scans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "linkfinder_url_scans" (
    "id" TEXT NOT NULL,
    "scan_id" TEXT NOT NULL,
    "url" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "result" TEXT,
    "error" TEXT,
    "stdout" TEXT,
    "stderr" TEXT,
    "command" TEXT,
    "execution_time" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "scope_target_id" TEXT,

    CONSTRAINT "linkfinder_url_scans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "waybackurls_scans" (
    "id" TEXT NOT NULL,
    "scan_id" TEXT NOT NULL,
    "url" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "result" TEXT,
    "error" TEXT,
    "stdout" TEXT,
    "stderr" TEXT,
    "command" TEXT,
    "execution_time" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "scope_target_id" TEXT,

    CONSTRAINT "waybackurls_scans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "gau_url_scans" (
    "id" TEXT NOT NULL,
    "scan_id" TEXT NOT NULL,
    "url" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "result" TEXT,
    "error" TEXT,
    "stdout" TEXT,
    "stderr" TEXT,
    "command" TEXT,
    "execution_time" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "scope_target_id" TEXT,

    CONSTRAINT "gau_url_scans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ffuf_url_scans" (
    "id" TEXT NOT NULL,
    "scan_id" TEXT NOT NULL,
    "url" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "result" TEXT,
    "error" TEXT,
    "stdout" TEXT,
    "stderr" TEXT,
    "command" TEXT,
    "execution_time" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "scope_target_id" TEXT,

    CONSTRAINT "ffuf_url_scans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ffuf_configs" (
    "id" TEXT NOT NULL,
    "scope_target_id" TEXT NOT NULL,
    "config" JSONB NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ffuf_configs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ffuf_wordlists" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "path" TEXT NOT NULL,
    "size" INTEGER NOT NULL DEFAULT 0,
    "file_size" BIGINT NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ffuf_wordlists_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "consolidated_subdomains" (
    "id" TEXT NOT NULL,
    "scope_target_id" TEXT NOT NULL,
    "subdomain" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "consolidated_subdomains_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "consolidated_company_domains" (
    "id" TEXT NOT NULL,
    "scope_target_id" TEXT NOT NULL,
    "domain" TEXT NOT NULL,
    "source" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "consolidated_company_domains_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "consolidated_network_ranges" (
    "id" TEXT NOT NULL,
    "scope_target_id" TEXT NOT NULL,
    "cidr_block" TEXT NOT NULL,
    "asn" TEXT,
    "organization" TEXT,
    "description" TEXT,
    "country" TEXT,
    "source" TEXT NOT NULL,
    "scan_type" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "consolidated_network_ranges_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "consolidated_attack_surface_assets" (
    "id" TEXT NOT NULL,
    "scope_target_id" TEXT NOT NULL,
    "asset_type" "AttackSurfaceAssetType" NOT NULL,
    "asset_identifier" TEXT NOT NULL,
    "asset_subtype" TEXT,
    "asn_number" TEXT,
    "asn_organization" TEXT,
    "asn_description" TEXT,
    "asn_country" TEXT,
    "cidr_block" TEXT,
    "subnet_size" INTEGER,
    "responsive_ip_count" INTEGER,
    "responsive_port_count" INTEGER,
    "ip_address" TEXT,
    "ip_type" TEXT,
    "dnsx_a_records" TEXT[],
    "amass_a_records" TEXT[],
    "httpx_sources" TEXT[],
    "url" TEXT,
    "domain" TEXT,
    "port" INTEGER,
    "protocol" TEXT,
    "status_code" INTEGER,
    "title" TEXT,
    "web_server" TEXT,
    "technologies" TEXT[],
    "content_length" INTEGER,
    "response_time_ms" DOUBLE PRECISION,
    "screenshot_path" TEXT,
    "ssl_info" JSONB,
    "http_response_headers" JSONB,
    "findings_json" JSONB,
    "cloud_provider" TEXT,
    "cloud_service_type" TEXT,
    "cloud_region" TEXT,
    "fqdn" TEXT,
    "root_domain" TEXT,
    "subdomain" TEXT,
    "registrar" TEXT,
    "creation_date" TIMESTAMP(3),
    "expiration_date" TIMESTAMP(3),
    "name_servers" TEXT[],
    "whois_info" JSONB,
    "ssl_certificate" JSONB,
    "ssl_expiry_date" TIMESTAMP(3),
    "ssl_issuer" TEXT,
    "resolved_ips" TEXT[],
    "mail_servers" TEXT[],
    "spf_record" TEXT,
    "dkim_record" TEXT,
    "dmarc_record" TEXT,
    "txt_records" TEXT[],
    "mx_records" TEXT[],
    "ns_records" TEXT[],
    "a_records" TEXT[],
    "aaaa_records" TEXT[],
    "cname_records" TEXT[],
    "soa_record" JSONB,
    "last_dns_scan" TIMESTAMP(3),
    "last_ssl_scan" TIMESTAMP(3),
    "last_whois_scan" TIMESTAMP(3),
    "last_updated" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "consolidated_attack_surface_assets_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "consolidated_attack_surface_relationships" (
    "id" TEXT NOT NULL,
    "parent_asset_id" TEXT NOT NULL,
    "child_asset_id" TEXT NOT NULL,
    "relationship_type" TEXT NOT NULL,
    "relationship_data" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "consolidated_attack_surface_relationships_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "consolidated_attack_surface_dns_records" (
    "id" TEXT NOT NULL,
    "asset_id" TEXT NOT NULL,
    "record_type" TEXT NOT NULL,
    "record_value" TEXT NOT NULL,
    "ttl" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "consolidated_attack_surface_dns_records_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "consolidated_attack_surface_metadata" (
    "id" TEXT NOT NULL,
    "asset_id" TEXT NOT NULL,
    "metadata_type" TEXT NOT NULL,
    "metadata_key" TEXT NOT NULL,
    "metadata_value" TEXT,
    "metadata_json" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "consolidated_attack_surface_metadata_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "threat_model" (
    "id" TEXT NOT NULL,
    "scope_target_id" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "url" TEXT NOT NULL,
    "mechanism" TEXT,
    "target_object" TEXT,
    "steps" TEXT,
    "security_controls" TEXT,
    "impact_customer_data" TEXT,
    "impact_attacker_scope" TEXT,
    "impact_company_reputation" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "threat_model_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notable_objects" (
    "id" TEXT NOT NULL,
    "scope_target_id" TEXT NOT NULL,
    "object_name" TEXT NOT NULL,
    "object_json" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notable_objects_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "security_controls_notes" (
    "id" TEXT NOT NULL,
    "scope_target_id" TEXT NOT NULL,
    "control_name" TEXT NOT NULL,
    "note" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "security_controls_notes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "application_questions_answers" (
    "id" TEXT NOT NULL,
    "scope_target_id" TEXT NOT NULL,
    "question" TEXT NOT NULL,
    "answer" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "application_questions_answers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "mechanisms_examples" (
    "id" TEXT NOT NULL,
    "scope_target_id" TEXT NOT NULL,
    "mechanism" TEXT NOT NULL,
    "url" TEXT NOT NULL,
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "mechanisms_examples_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "google_dorking_domains" (
    "id" TEXT NOT NULL,
    "scope_target_id" TEXT NOT NULL,
    "domain" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "google_dorking_domains_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "reverse_whois_domains" (
    "id" TEXT NOT NULL,
    "scope_target_id" TEXT NOT NULL,
    "domain" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "reverse_whois_domains_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "scans_asset_id_tool_type_idx" ON "scans"("asset_id", "tool_type");

-- CreateIndex
CREATE INDEX "scans_status_idx" ON "scans"("status");

-- CreateIndex
CREATE INDEX "scans_created_at_idx" ON "scans"("created_at" DESC);

-- CreateIndex
CREATE INDEX "scan_results_scan_id_idx" ON "scan_results"("scan_id");

-- CreateIndex
CREATE INDEX "target_urls_scope_target_id_idx" ON "target_urls"("scope_target_id");

-- CreateIndex
CREATE UNIQUE INDEX "target_urls_url_scope_target_id_key" ON "target_urls"("url", "scope_target_id");

-- CreateIndex
CREATE UNIQUE INDEX "user_search_permissions_user_id_key" ON "user_search_permissions"("user_id");

-- CreateIndex
CREATE INDEX "user_scope_access_user_id_idx" ON "user_scope_access"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "user_scope_access_user_id_scope_target_id_key" ON "user_scope_access"("user_id", "scope_target_id");

-- CreateIndex
CREATE UNIQUE INDEX "api_keys_tool_name_api_key_name_key" ON "api_keys"("tool_name", "api_key_name");

-- CreateIndex
CREATE UNIQUE INDEX "ai_api_keys_provider_api_key_name_key" ON "ai_api_keys"("provider", "api_key_name");

-- CreateIndex
CREATE UNIQUE INDEX "auto_scan_state_scope_target_id_key" ON "auto_scan_state"("scope_target_id");

-- CreateIndex
CREATE UNIQUE INDEX "amass_scans_scan_id_key" ON "amass_scans"("scan_id");

-- CreateIndex
CREATE UNIQUE INDEX "amass_intel_scans_scan_id_key" ON "amass_intel_scans"("scan_id");

-- CreateIndex
CREATE UNIQUE INDEX "httpx_scans_scan_id_key" ON "httpx_scans"("scan_id");

-- CreateIndex
CREATE UNIQUE INDEX "gau_scans_scan_id_key" ON "gau_scans"("scan_id");

-- CreateIndex
CREATE UNIQUE INDEX "sublist3r_scans_scan_id_key" ON "sublist3r_scans"("scan_id");

-- CreateIndex
CREATE UNIQUE INDEX "assetfinder_scans_scan_id_key" ON "assetfinder_scans"("scan_id");

-- CreateIndex
CREATE UNIQUE INDEX "ctl_scans_scan_id_key" ON "ctl_scans"("scan_id");

-- CreateIndex
CREATE UNIQUE INDEX "subfinder_scans_scan_id_key" ON "subfinder_scans"("scan_id");

-- CreateIndex
CREATE UNIQUE INDEX "shuffledns_scans_scan_id_key" ON "shuffledns_scans"("scan_id");

-- CreateIndex
CREATE UNIQUE INDEX "cewl_scans_scan_id_key" ON "cewl_scans"("scan_id");

-- CreateIndex
CREATE UNIQUE INDEX "gospider_scans_scan_id_key" ON "gospider_scans"("scan_id");

-- CreateIndex
CREATE UNIQUE INDEX "subdomainizer_scans_scan_id_key" ON "subdomainizer_scans"("scan_id");

-- CreateIndex
CREATE UNIQUE INDEX "nuclei_screenshots_scan_id_key" ON "nuclei_screenshots"("scan_id");

-- CreateIndex
CREATE UNIQUE INDEX "metadata_scans_scan_id_key" ON "metadata_scans"("scan_id");

-- CreateIndex
CREATE UNIQUE INDEX "cloud_enum_scans_scan_id_key" ON "cloud_enum_scans"("scan_id");

-- CreateIndex
CREATE UNIQUE INDEX "metabigor_company_scans_scan_id_key" ON "metabigor_company_scans"("scan_id");

-- CreateIndex
CREATE UNIQUE INDEX "github_recon_scans_scan_id_key" ON "github_recon_scans"("scan_id");

-- CreateIndex
CREATE UNIQUE INDEX "shodan_company_scans_scan_id_key" ON "shodan_company_scans"("scan_id");

-- CreateIndex
CREATE UNIQUE INDEX "censys_company_scans_scan_id_key" ON "censys_company_scans"("scan_id");

-- CreateIndex
CREATE UNIQUE INDEX "securitytrails_company_scans_scan_id_key" ON "securitytrails_company_scans"("scan_id");

-- CreateIndex
CREATE UNIQUE INDEX "ip_port_scans_scan_id_key" ON "ip_port_scans"("scan_id");

-- CreateIndex
CREATE UNIQUE INDEX "live_web_servers_scan_id_ip_address_port_protocol_key" ON "live_web_servers"("scan_id", "ip_address", "port", "protocol");

-- CreateIndex
CREATE UNIQUE INDEX "nuclei_scans_scan_id_key" ON "nuclei_scans"("scan_id");

-- CreateIndex
CREATE UNIQUE INDEX "nuclei_configs_scope_target_id_key" ON "nuclei_configs"("scope_target_id");

-- CreateIndex
CREATE UNIQUE INDEX "katana_url_scans_scan_id_key" ON "katana_url_scans"("scan_id");

-- CreateIndex
CREATE UNIQUE INDEX "linkfinder_url_scans_scan_id_key" ON "linkfinder_url_scans"("scan_id");

-- CreateIndex
CREATE UNIQUE INDEX "waybackurls_scans_scan_id_key" ON "waybackurls_scans"("scan_id");

-- CreateIndex
CREATE UNIQUE INDEX "gau_url_scans_scan_id_key" ON "gau_url_scans"("scan_id");

-- CreateIndex
CREATE UNIQUE INDEX "ffuf_url_scans_scan_id_key" ON "ffuf_url_scans"("scan_id");

-- CreateIndex
CREATE UNIQUE INDEX "ffuf_configs_scope_target_id_key" ON "ffuf_configs"("scope_target_id");

-- CreateIndex
CREATE UNIQUE INDEX "consolidated_subdomains_scope_target_id_subdomain_key" ON "consolidated_subdomains"("scope_target_id", "subdomain");

-- CreateIndex
CREATE UNIQUE INDEX "consolidated_company_domains_scope_target_id_domain_key" ON "consolidated_company_domains"("scope_target_id", "domain");

-- CreateIndex
CREATE UNIQUE INDEX "consolidated_network_ranges_scope_target_id_cidr_block_sour_key" ON "consolidated_network_ranges"("scope_target_id", "cidr_block", "source");

-- CreateIndex
CREATE INDEX "consolidated_attack_surface_assets_scope_target_id_idx" ON "consolidated_attack_surface_assets"("scope_target_id");

-- CreateIndex
CREATE INDEX "consolidated_attack_surface_assets_asset_type_idx" ON "consolidated_attack_surface_assets"("asset_type");

-- CreateIndex
CREATE INDEX "consolidated_attack_surface_assets_ip_address_idx" ON "consolidated_attack_surface_assets"("ip_address");

-- CreateIndex
CREATE INDEX "consolidated_attack_surface_assets_domain_idx" ON "consolidated_attack_surface_assets"("domain");

-- CreateIndex
CREATE INDEX "consolidated_attack_surface_assets_fqdn_idx" ON "consolidated_attack_surface_assets"("fqdn");

-- CreateIndex
CREATE UNIQUE INDEX "consolidated_attack_surface_assets_scope_target_id_asset_ty_key" ON "consolidated_attack_surface_assets"("scope_target_id", "asset_type", "asset_identifier");

-- CreateIndex
CREATE UNIQUE INDEX "consolidated_attack_surface_relationships_parent_asset_id_c_key" ON "consolidated_attack_surface_relationships"("parent_asset_id", "child_asset_id", "relationship_type");

-- CreateIndex
CREATE UNIQUE INDEX "consolidated_attack_surface_dns_records_asset_id_record_typ_key" ON "consolidated_attack_surface_dns_records"("asset_id", "record_type", "record_value");

-- CreateIndex
CREATE UNIQUE INDEX "consolidated_attack_surface_metadata_asset_id_metadata_type_key" ON "consolidated_attack_surface_metadata"("asset_id", "metadata_type", "metadata_key");

-- CreateIndex
CREATE UNIQUE INDEX "notable_objects_scope_target_id_object_name_key" ON "notable_objects"("scope_target_id", "object_name");

-- CreateIndex
CREATE UNIQUE INDEX "google_dorking_domains_scope_target_id_domain_key" ON "google_dorking_domains"("scope_target_id", "domain");

-- CreateIndex
CREATE UNIQUE INDEX "reverse_whois_domains_scope_target_id_domain_key" ON "reverse_whois_domains"("scope_target_id", "domain");

-- AddForeignKey
ALTER TABLE "scans" ADD CONSTRAINT "scans_asset_id_fkey" FOREIGN KEY ("asset_id") REFERENCES "assets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "scan_results" ADD CONSTRAINT "scan_results_scan_id_fkey" FOREIGN KEY ("scan_id") REFERENCES "scans"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "auto_scan_sessions" ADD CONSTRAINT "auto_scan_sessions_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "target_urls" ADD CONSTRAINT "target_urls_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_scope_access" ADD CONSTRAINT "user_scope_access_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "auto_scan_state" ADD CONSTRAINT "auto_scan_state_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "amass_scans" ADD CONSTRAINT "amass_scans_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "amass_intel_scans" ADD CONSTRAINT "amass_intel_scans_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "httpx_scans" ADD CONSTRAINT "httpx_scans_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "gau_scans" ADD CONSTRAINT "gau_scans_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sublist3r_scans" ADD CONSTRAINT "sublist3r_scans_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "assetfinder_scans" ADD CONSTRAINT "assetfinder_scans_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ctl_scans" ADD CONSTRAINT "ctl_scans_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "subfinder_scans" ADD CONSTRAINT "subfinder_scans_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "shuffledns_scans" ADD CONSTRAINT "shuffledns_scans_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cewl_scans" ADD CONSTRAINT "cewl_scans_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "gospider_scans" ADD CONSTRAINT "gospider_scans_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "subdomainizer_scans" ADD CONSTRAINT "subdomainizer_scans_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "nuclei_screenshots" ADD CONSTRAINT "nuclei_screenshots_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "metadata_scans" ADD CONSTRAINT "metadata_scans_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cloud_enum_scans" ADD CONSTRAINT "cloud_enum_scans_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "metabigor_company_scans" ADD CONSTRAINT "metabigor_company_scans_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "github_recon_scans" ADD CONSTRAINT "github_recon_scans_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "shodan_company_scans" ADD CONSTRAINT "shodan_company_scans_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "censys_company_scans" ADD CONSTRAINT "censys_company_scans_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "securitytrails_company_scans" ADD CONSTRAINT "securitytrails_company_scans_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ip_port_scans" ADD CONSTRAINT "ip_port_scans_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "discovered_live_ips" ADD CONSTRAINT "discovered_live_ips_scan_id_fkey" FOREIGN KEY ("scan_id") REFERENCES "ip_port_scans"("scan_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "live_web_servers" ADD CONSTRAINT "live_web_servers_scan_id_fkey" FOREIGN KEY ("scan_id") REFERENCES "ip_port_scans"("scan_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "nuclei_scans" ADD CONSTRAINT "nuclei_scans_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "nuclei_configs" ADD CONSTRAINT "nuclei_configs_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "katana_url_scans" ADD CONSTRAINT "katana_url_scans_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "linkfinder_url_scans" ADD CONSTRAINT "linkfinder_url_scans_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "waybackurls_scans" ADD CONSTRAINT "waybackurls_scans_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "gau_url_scans" ADD CONSTRAINT "gau_url_scans_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ffuf_url_scans" ADD CONSTRAINT "ffuf_url_scans_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ffuf_configs" ADD CONSTRAINT "ffuf_configs_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "consolidated_subdomains" ADD CONSTRAINT "consolidated_subdomains_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "consolidated_company_domains" ADD CONSTRAINT "consolidated_company_domains_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "consolidated_network_ranges" ADD CONSTRAINT "consolidated_network_ranges_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "consolidated_attack_surface_assets" ADD CONSTRAINT "consolidated_attack_surface_assets_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "consolidated_attack_surface_relationships" ADD CONSTRAINT "consolidated_attack_surface_relationships_parent_asset_id_fkey" FOREIGN KEY ("parent_asset_id") REFERENCES "consolidated_attack_surface_assets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "consolidated_attack_surface_relationships" ADD CONSTRAINT "consolidated_attack_surface_relationships_child_asset_id_fkey" FOREIGN KEY ("child_asset_id") REFERENCES "consolidated_attack_surface_assets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "consolidated_attack_surface_dns_records" ADD CONSTRAINT "consolidated_attack_surface_dns_records_asset_id_fkey" FOREIGN KEY ("asset_id") REFERENCES "consolidated_attack_surface_assets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "consolidated_attack_surface_metadata" ADD CONSTRAINT "consolidated_attack_surface_metadata_asset_id_fkey" FOREIGN KEY ("asset_id") REFERENCES "consolidated_attack_surface_assets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "threat_model" ADD CONSTRAINT "threat_model_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notable_objects" ADD CONSTRAINT "notable_objects_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "security_controls_notes" ADD CONSTRAINT "security_controls_notes_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "application_questions_answers" ADD CONSTRAINT "application_questions_answers_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mechanisms_examples" ADD CONSTRAINT "mechanisms_examples_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "google_dorking_domains" ADD CONSTRAINT "google_dorking_domains_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reverse_whois_domains" ADD CONSTRAINT "reverse_whois_domains_scope_target_id_fkey" FOREIGN KEY ("scope_target_id") REFERENCES "scope_targets"("id") ON DELETE CASCADE ON UPDATE CASCADE;
