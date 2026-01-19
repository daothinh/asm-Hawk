import Link from 'next/link';

export default function HomePage() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 flex items-center justify-center">
      <div className="text-center space-y-8 px-4">
        {/* Logo */}
        <div className="space-y-4">
          <h1 className="text-6xl font-bold bg-gradient-to-r from-cyan-400 via-blue-500 to-purple-600 bg-clip-text text-transparent">
            ASM-Hawk
          </h1>
          <p className="text-xl text-slate-400 max-w-md mx-auto">
            Monitor and protect your attack surface with real-time threat intelligence
          </p>
        </div>

        {/* CTA Buttons */}
        <div className="flex gap-4 justify-center">
          <Link
            href="/login"
            className="px-8 py-3 bg-gradient-to-r from-cyan-500 to-blue-600 text-white font-semibold rounded-lg shadow-lg hover:from-cyan-600 hover:to-blue-700 transition-all duration-200"
          >
            Sign In
          </Link>
          <Link
            href="/register"
            className="px-8 py-3 bg-slate-800 text-white font-semibold rounded-lg border border-slate-700 hover:bg-slate-700 transition-all duration-200"
          >
            Get Started
          </Link>
        </div>

        {/* Features */}
        <div className="grid md:grid-cols-3 gap-6 mt-16 max-w-4xl mx-auto">
          {[
            {
              title: 'Asset Discovery',
              description: 'Automatically discover domains, subdomains, and IPs',
              icon: '🔍',
            },
            {
              title: 'Threat Intelligence',
              description: 'Real-time data from VirusTotal, Censys, and more',
              icon: '🛡️',
            },
            {
              title: 'Risk Scoring',
              description: 'AI-powered risk assessment and prioritization',
              icon: '📊',
            },
          ].map((feature) => (
            <div
              key={feature.title}
              className="bg-slate-800/50 backdrop-blur-lg rounded-xl p-6 border border-slate-700"
            >
              <div className="text-4xl mb-4">{feature.icon}</div>
              <h3 className="text-lg font-semibold text-white mb-2">{feature.title}</h3>
              <p className="text-slate-400 text-sm">{feature.description}</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
