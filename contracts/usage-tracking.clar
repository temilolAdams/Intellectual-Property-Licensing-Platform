;; Usage Tracking Contract

(define-data-var next-usage-id uint u0)

(define-map usage-records
  { usage-id: uint }
  {
    license-id: uint,
    usage-type: (string-ascii 50),
    usage-amount: uint,
    timestamp: uint
  }
)

(define-public (record-usage (license-id uint) (usage-type (string-ascii 50)) (usage-amount uint))
  (let
    ((new-usage-id (var-get next-usage-id)))
    (asserts! (contract-call? .license-agreement is-license-active license-id) (err u403))
    (map-set usage-records
      { usage-id: new-usage-id }
      {
        license-id: license-id,
        usage-type: usage-type,
        usage-amount: usage-amount,
        timestamp: block-height
      }
    )
    (var-set next-usage-id (+ new-usage-id u1))
    (ok new-usage-id)
  )
)

(define-read-only (get-usage-record (usage-id uint))
  (map-get? usage-records { usage-id: usage-id })
)

(define-read-only (get-total-usage (license-id uint))
  (fold + (map get-usage-amount (filter-usage-by-license license-id)) u0)
)

(define-private (filter-usage-by-license (license-id uint))
  (filter is-matching-license (map-to-list usage-records))
)

(define-private (is-matching-license (entry {usage-id: uint, usage: (optional {license-id: uint, usage-type: (string-ascii 50), usage-amount: uint, timestamp: uint})}))
  (match (get usage entry)
    usage (is-eq (get license-id usage) license-id)
    false
  )
)

(define-private (get-usage-amount (entry {usage-id: uint, usage: (optional {license-id: uint, usage-type: (string-ascii 50), usage-amount: uint, timestamp: uint})}))
  (match (get usage entry)
    usage (get usage-amount usage)
    u0
  )
)

