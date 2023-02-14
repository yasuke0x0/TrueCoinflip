export interface BetModel {
    amount: number // in wei
    placeBlockNumber: string
    gambler: string
    isSettled: boolean
    outcome: "0" | "1" | "2" // 0 = ongoing, 1 = win, 2 = loose
    winAmount: number // in wei
}

export interface WalletModel {
    address: string
    balance: number
}

export interface BetPlacedEventModel{
    amount: string
    betId: string
    gambler: string
}

export interface BetSettledEventModel{
    betId: string
    gambler: string
    amount: number
    outcome: | "1" | "2"
    winAmount: number
}

