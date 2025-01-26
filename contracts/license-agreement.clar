;; License Agreement Contract

(define-data-var next-license-id uint u0)

(define-map license-agreements
  { license-id: uint }
  {
    asset-id: uint,
    licensor: principal,
    licensee: principal,
    terms: (string-utf8 1000),
    start-date: uint,
    end-date: uint,
    royalty-rate: uint,
    status: (string-ascii 20)
  }
)

(define-public (create-license-agreement
    (asset-id uint)
    (licensee principal)
    (terms (string-utf8 1000))
    (start-date uint)
    (end-date uint)
    (royalty-rate uint))
  (let
    ((new-license-id (var-get next-license-id))
     (caller tx-sender))
    (match (contract-call? .ip-asset-management get-ip-asset-owner asset-id)
      owner (begin
        (asserts! (is-eq caller owner) (err u403))
        (map-set license-agreements
          { license-id: new-license-id }
          {
            asset-id: asset-id,
            licensor: caller,
            licensee: licensee,
            terms: terms,
            start-date: start-date,
            end-date: end-date,
            royalty-rate: royalty-rate,
            status: "active"
          }
        )
        (var-set next-license-id (+ new-license-id u1))
        (ok new-license-id)
      )
      (err u404)
    )
  )
)

(define-public (terminate-license-agreement (license-id uint))
  (let ((caller tx-sender))
    (match (map-get? license-agreements { license-id: license-id })
      agreement (begin
        (asserts! (or (is-eq caller (get licensor agreement)) (is-eq caller (get licensee agreement))) (err u403))
        (map-set license-agreements
          { license-id: license-id }
          (merge agreement { status: "terminated" })
        )
        (ok true)
      )
      (err u404)
    )
  )
)

(define-read-only (get-license-agreement (license-id uint))
  (map-get? license-agreements { license-id: license-id })
)

(define-read-only (is-license-active (license-id uint))
  (match (map-get? license-agreements { license-id: license-id })
    agreement (and
      (is-eq (get status agreement) "active")
      (>= block-height (get start-date agreement))
      (<= block-height (get end-date agreement)))
    false
  )
)

