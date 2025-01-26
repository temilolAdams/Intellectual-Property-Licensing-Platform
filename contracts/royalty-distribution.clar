;; Royalty Distribution Contract

(define-constant ERR_INSUFFICIENT_BALANCE u100)
(define-constant ERR_TRANSFER_FAILED u101)

(define-map royalty-balances
  { asset-id: uint }
  { balance: uint }
)

(define-public (distribute-royalties (license-id uint) (amount uint))
  (let
    ((caller tx-sender))
    (match (contract-call? .license-agreement get-license-agreement license-id)
      agreement (let
        ((asset-id (get asset-id agreement))
         (licensor (get licensor agreement))
         (royalty-rate (get royalty-rate agreement))
         (royalty-amount (/ (* amount royalty-rate) u10000)))
        (try! (stx-transfer? amount caller (as-contract tx-sender)))
        (try! (pay-royalty asset-id licensor royalty-amount))
        (ok royalty-amount)
      )
      (err u404)
    )
  )
)

(define-private (pay-royalty (asset-id uint) (recipient principal) (amount uint))
  (let
    ((current-balance (default-to { balance: u0 } (map-get? royalty-balances { asset-id: asset-id }))))
    (map-set royalty-balances
      { asset-id: asset-id }
      { balance: (+ (get balance current-balance) amount) }
    )
    (as-contract (stx-transfer? amount tx-sender recipient))
  )
)

(define-public (withdraw-royalties (asset-id uint))
  (let
    ((caller tx-sender)
     (balance (default-to { balance: u0 } (map-get? royalty-balances { asset-id: asset-id }))))
    (asserts! (is-eq caller (unwrap! (contract-call? .ip-asset-management get-ip-asset-owner asset-id) (err u403))) (err u403))
    (asserts! (> (get balance balance) u0) (err ERR_INSUFFICIENT_BALANCE))
    (map-set royalty-balances
      { asset-id: asset-id }
      { balance: u0 }
    )
    (as-contract (stx-transfer? (get balance balance) tx-sender caller))
  )
)

(define-read-only (get-royalty-balance (asset-id uint))
  (default-to { balance: u0 } (map-get? royalty-balances { asset-id: asset-id }))
)

