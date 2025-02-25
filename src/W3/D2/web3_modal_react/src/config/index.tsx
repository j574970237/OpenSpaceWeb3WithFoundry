import { WagmiAdapter } from '@reown/appkit-adapter-wagmi'
import { mainnet, arbitrum, sepolia } from '@reown/appkit/networks'
import type { AppKitNetwork } from '@reown/appkit/networks'

// Get projectId from https://cloud.reown.com
export const projectId = import.meta.env.VITE_PROJECT_ID || "a7142e1589fe0351ab2aab4b7c060040" // this is a public projectId only to use on localhost

if (!projectId) {
  throw new Error('Project ID is not defined')
}

export const metadata = {
    name: 'OpenBank',
    description: 'Welcome To OpenBank',
    url: 'https://web3modalreact-lovat.vercel.app', // origin must match your domain & subdomain
    icons: ['https://avatars.githubusercontent.com/u/179229932']
  }

// for custom networks visit -> https://docs.reown.com/appkit/react/core/custom-networks
export const networks = [mainnet, arbitrum, sepolia] as [AppKitNetwork, ...AppKitNetwork[]]

//Set up the Wagmi Adapter (Config)
export const wagmiAdapter = new WagmiAdapter({
  projectId,
  networks
})

export const config = wagmiAdapter.wagmiConfig