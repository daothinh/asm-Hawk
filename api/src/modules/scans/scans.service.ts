import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateScanDto, UpdateScanDto } from './dto';
import { ReconToolType, ScanJobStatus } from '@prisma/client';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

// Map tool types to container names and commands
const TOOL_CONFIG: Record<ReconToolType, { container: string; command: (domain: string) => string[] }> = {
    SUBFINDER: {
        container: 'asm-hawk-subfinder',
        command: (domain) => ['subfinder', '-d', domain, '-silent'],
    },
    HTTPX: {
        container: 'asm-hawk-httpx',
        command: (domain) => ['httpx', '-u', domain, '-silent', '-json'],
    },
    NUCLEI: {
        container: 'asm-hawk-nuclei',
        command: (domain) => ['nuclei', '-u', domain, '-silent', '-json'],
    },
    KATANA: {
        container: 'asm-hawk-katana',
        command: (domain) => ['katana', '-u', domain, '-silent'],
    },
    DNSX: {
        container: 'asm-hawk-dnsx',
        command: (domain) => ['dnsx', '-d', domain, '-silent'],
    },
    FFUF: {
        container: 'asm-hawk-ffuf',
        command: (domain) => ['ffuf', '-u', `https://${domain}/FUZZ`, '-w', '/wordlists/common.txt', '-o', '/dev/stdout'],
    },
    GOSPIDER: {
        container: 'asm-hawk-gospider',
        command: (domain) => ['gospider', '-s', `https://${domain}`, '-q'],
    },
    WAYBACKURLS: {
        container: 'asm-hawk-waybackurls',
        command: (domain) => ['waybackurls', domain],
    },
    SHUFFLEDNS: {
        container: 'asm-hawk-shuffledns',
        command: (domain) => ['shuffledns', '-d', domain, '-silent'],
    },
    CEWL: {
        container: 'asm-hawk-cewl',
        command: (domain) => ['cewl', `https://${domain}`, '-d', '2'],
    },
    ASSETFINDER: {
        container: 'asm-hawk-assetfinder',
        command: (domain) => ['assetfinder', domain],
    },
    METABIGOR: {
        container: 'asm-hawk-metabigor',
        command: (domain) => ['metabigor', 'net', '-org', domain],
    },
    SUBLIST3R: {
        container: 'asm-hawk-sublist3r',
        command: (domain) => ['sublist3r', '-d', domain, '-o', '/dev/stdout'],
    },
    SUBDOMAINIZER: {
        container: 'asm-hawk-subdomainizer',
        command: (domain) => ['python3', 'SubDomainizer.py', '-u', `https://${domain}`],
    },
    GITHUB_RECON: {
        container: 'asm-hawk-github-recon',
        command: (domain) => ['github-recon', domain],
    },
    CLOUD_ENUM: {
        container: 'asm-hawk-cloud-enum',
        command: (domain) => ['cloud_enum', '-k', domain],
    },
    LINKFINDER: {
        container: 'asm-hawk-linkfinder',
        command: (domain) => ['linkfinder', '-i', `https://${domain}`, '-o', 'cli'],
    },
};

@Injectable()
export class ScansService {
    private readonly logger = new Logger(ScansService.name);

    constructor(private prisma: PrismaService) { }

    async create(createScanDto: CreateScanDto) {
        // Verify asset exists
        const asset = await this.prisma.asset.findUnique({
            where: { id: createScanDto.assetId },
        });

        if (!asset) {
            throw new NotFoundException(`Asset ${createScanDto.assetId} not found`);
        }

        // Create scan record
        const scan = await this.prisma.scan.create({
            data: {
                assetId: createScanDto.assetId,
                toolType: createScanDto.toolType,
                status: ScanJobStatus.PENDING,
            },
            include: {
                asset: true,
            },
        });

        // Execute scan in background
        this.executeScan(scan.id, asset.domain, createScanDto.toolType);

        return scan;
    }

    private async executeScan(scanId: string, domain: string, toolType: ReconToolType) {
        const startTime = Date.now();
        const config = TOOL_CONFIG[toolType];

        try {
            // Update status to running
            await this.prisma.scan.update({
                where: { id: scanId },
                data: {
                    status: ScanJobStatus.RUNNING,
                    startedAt: new Date(),
                    command: `docker exec ${config.container} ${config.command(domain).join(' ')}`,
                },
            });

            // Execute command in container
            const command = ['docker', 'exec', config.container, ...config.command(domain)].join(' ');
            this.logger.log(`Executing: ${command}`);

            const { stdout, stderr } = await execAsync(command, {
                timeout: 300000, // 5 minutes timeout
                maxBuffer: 50 * 1024 * 1024, // 50MB buffer
            });

            const executionTime = `${((Date.now() - startTime) / 1000).toFixed(2)}s`;

            // Update scan with results
            await this.prisma.scan.update({
                where: { id: scanId },
                data: {
                    status: ScanJobStatus.COMPLETED,
                    stdout: stdout,
                    stderr: stderr || null,
                    executionTime,
                    completedAt: new Date(),
                },
            });

            // Parse and store results
            await this.parseAndStoreResults(scanId, toolType, stdout);

            this.logger.log(`Scan ${scanId} completed in ${executionTime}`);
        } catch (error) {
            const executionTime = `${((Date.now() - startTime) / 1000).toFixed(2)}s`;

            await this.prisma.scan.update({
                where: { id: scanId },
                data: {
                    status: ScanJobStatus.FAILED,
                    stderr: error.message,
                    executionTime,
                    completedAt: new Date(),
                },
            });

            this.logger.error(`Scan ${scanId} failed: ${error.message}`);
        }
    }

    private async parseAndStoreResults(scanId: string, toolType: ReconToolType, stdout: string) {
        if (!stdout || stdout.trim() === '') return;

        const lines = stdout.trim().split('\n').filter(line => line.trim());

        // Store each line as a result
        const results = lines.map(line => ({
            scanId,
            resultType: toolType.toLowerCase(),
            data: this.parseResultLine(toolType, line),
        }));

        if (results.length > 0) {
            await this.prisma.scanResult.createMany({
                data: results,
            });
        }
    }

    private parseResultLine(toolType: ReconToolType, line: string): object {
        // Try to parse as JSON first
        try {
            return JSON.parse(line);
        } catch {
            // Return as simple value
            return { value: line.trim() };
        }
    }

    async findAll(options: {
        assetId?: string;
        toolType?: ReconToolType;
        status?: ScanJobStatus;
        skip?: number;
        take?: number;
    }) {
        const { assetId, toolType, status, skip = 0, take = 20 } = options;

        const where: any = {};
        if (assetId) where.assetId = assetId;
        if (toolType) where.toolType = toolType;
        if (status) where.status = status;

        const [scans, total] = await Promise.all([
            this.prisma.scan.findMany({
                where,
                skip,
                take,
                orderBy: { createdAt: 'desc' },
                include: {
                    asset: {
                        select: { id: true, domain: true },
                    },
                    _count: {
                        select: { scanResults: true },
                    },
                },
            }),
            this.prisma.scan.count({ where }),
        ]);

        return {
            data: scans,
            meta: {
                total,
                skip,
                take,
            },
        };
    }

    async findOne(id: string) {
        const scan = await this.prisma.scan.findUnique({
            where: { id },
            include: {
                asset: true,
                scanResults: {
                    orderBy: { createdAt: 'asc' },
                },
            },
        });

        if (!scan) {
            throw new NotFoundException(`Scan ${id} not found`);
        }

        return scan;
    }

    async findByAsset(assetId: string) {
        return this.prisma.scan.findMany({
            where: { assetId },
            orderBy: { createdAt: 'desc' },
            include: {
                _count: {
                    select: { scanResults: true },
                },
            },
        });
    }

    async cancel(id: string) {
        const scan = await this.findOne(id);

        if (scan.status !== ScanJobStatus.RUNNING && scan.status !== ScanJobStatus.PENDING) {
            throw new Error(`Cannot cancel scan with status ${scan.status}`);
        }

        // Note: In a real implementation, you'd need to track the process and kill it
        // For now, we just mark it as cancelled
        return this.prisma.scan.update({
            where: { id },
            data: {
                status: ScanJobStatus.CANCELLED,
                completedAt: new Date(),
            },
        });
    }

    async delete(id: string) {
        await this.findOne(id); // Verify exists
        return this.prisma.scan.delete({ where: { id } });
    }
}
