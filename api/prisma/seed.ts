import 'dotenv/config';
import { PrismaClient, Role, AssetType, AssetStatus } from '@prisma/client';
import { Pool } from 'pg';
import { PrismaPg } from '@prisma/adapter-pg';
import * as bcrypt from 'bcryptjs';

// Create Prisma client with pg adapter (Prisma 7)
const connectionString = process.env.DATABASE_URL;
const pool = new Pool({ connectionString });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter } as any);

async function main() {
    console.log('🌱 Seeding database...');

    // Clear existing data in order (respecting foreign keys)
    await prisma.searchHistory.deleteMany();
    await prisma.riskTag.deleteMany();
    await prisma.externalIntel.deleteMany();
    await prisma.attackResult.deleteMany();
    await prisma.reconResult.deleteMany();
    await prisma.asset.deleteMany();
    await prisma.user.deleteMany();

    console.log('🗑️  Cleared existing data');

    // Create users
    const hashedPassword = await bcrypt.hash('password123', 10);

    const admin = await prisma.user.create({
        data: {
            email: 'admin@asm-hawk.local',
            passwordHash: hashedPassword,
            fullName: 'Administrator',
            role: Role.ADMIN,
            isActive: true,
        },
    });

    const analyst = await prisma.user.create({
        data: {
            email: 'analyst@asm-hawk.local',
            passwordHash: hashedPassword,
            fullName: 'Security Analyst',
            role: Role.ANALYST,
            isActive: true,
        },
    });

    const viewer = await prisma.user.create({
        data: {
            email: 'viewer@asm-hawk.local',
            passwordHash: hashedPassword,
            fullName: 'Viewer User',
            role: Role.VIEWER,
            isActive: true,
        },
    });

    console.log('✅ Created users: admin, analyst, viewer');

    // Create sample assets
    const assets = await Promise.all([
        prisma.asset.create({
            data: {
                domain: 'example.com',
                ipAddress: '93.184.216.34',
                ipOwner: 'Edgecast Inc.',
                assetType: AssetType.DOMAIN,
                status: AssetStatus.ACTIVE,
                riskScore: 15.5,
                createdById: admin.id,
            },
        }),
        prisma.asset.create({
            data: {
                domain: 'api.example.com',
                ipAddress: '93.184.216.35',
                ipOwner: 'Edgecast Inc.',
                assetType: AssetType.SUBDOMAIN,
                status: AssetStatus.ACTIVE,
                riskScore: 22.0,
                createdById: analyst.id,
            },
        }),
        prisma.asset.create({
            data: {
                domain: 'suspicious-site.xyz',
                ipAddress: '45.33.32.156',
                ipOwner: 'Unknown Provider',
                assetType: AssetType.DOMAIN,
                status: AssetStatus.SUSPICIOUS,
                riskScore: 78.5,
                createdById: analyst.id,
            },
        }),
        prisma.asset.create({
            data: {
                domain: 'malware-host.ru',
                ipAddress: '185.220.101.45',
                ipOwner: 'Bulletproof Hosting',
                assetType: AssetType.DOMAIN,
                status: AssetStatus.CONFIRMED_MALICIOUS,
                riskScore: 95.0,
                createdById: admin.id,
            },
        }),
        prisma.asset.create({
            data: {
                domain: 'inactive-old.net',
                ipAddress: null,
                ipOwner: null,
                assetType: AssetType.DOMAIN,
                status: AssetStatus.INACTIVE,
                riskScore: 0,
                createdById: viewer.id,
            },
        }),
    ]);

    console.log(`✅ Created ${assets.length} sample assets`);

    // Create search history
    await prisma.searchHistory.createMany({
        data: [
            { userId: admin.id, searchQuery: 'example.com', searchType: 'DOMAIN', resultsCount: 2 },
            { userId: analyst.id, searchQuery: 'malware', searchType: 'KEYWORD', resultsCount: 1 },
            { userId: viewer.id, searchQuery: '45.33.32.156', searchType: 'IP', resultsCount: 1 },
        ],
    });

    console.log('✅ Created search history');

    // Summary
    console.log('\n📊 Seed Summary:');
    console.log('   - Users: 3 (admin, analyst, viewer)');
    console.log(`   - Assets: ${assets.length}`);
    console.log('   - Password for all users: password123');
    console.log('\n🎉 Database seeding completed!');
}

main()
    .catch((e) => {
        console.error('❌ Seed error:', e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
        await pool.end();
    });
