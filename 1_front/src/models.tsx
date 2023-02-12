export interface BetModel {
    amount: number
    placeBlockNumber: string
    gambler: string
    isSettled: boolean
    outcome: 0 | 1 | 2 // 0 = ongoing, 1 = win, 2 = loose
    winAmount: number // in wei
}

export interface WalletModel {
    address: string
    balance: number
}