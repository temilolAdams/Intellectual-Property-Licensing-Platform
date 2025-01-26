;; IP Asset Management Contract

(define-data-var next-asset-id uint u0)

(define-map ip-assets
  { asset-id: uint }
  {
    owner: principal,
    title: (string-ascii 100),
    description: (string-utf8 500),
    asset-type: (string-ascii 20),
    creation-date: uint,
    last-updated: uint
  }
)

(define-non-fungible-token ip-asset uint)

(define-public (create-ip-asset (title (string-ascii 100)) (description (string-utf8 500)) (asset-type (string-ascii 20)))
  (let
    ((new-asset-id (var-get next-asset-id))
     (caller tx-sender))
    (try! (nft-mint? ip-asset new-asset-id caller))
    (map-set ip-assets
      { asset-id: new-asset-id }
      {
        owner: caller,
        title: title,
        description: description,
        asset-type: asset-type,
        creation-date: block-height,
        last-updated: block-height
      }
    )
    (var-set next-asset-id (+ new-asset-id u1))
    (ok new-asset-id)
  )
)

(define-public (update-ip-asset (asset-id uint) (new-title (optional (string-ascii 100))) (new-description (optional (string-utf8 500))))
  (let ((caller tx-sender))
    (match (map-get? ip-assets { asset-id: asset-id })
      asset (begin
        (asserts! (is-eq caller (get owner asset)) (err u403))
        (map-set ip-assets
          { asset-id: asset-id }
          (merge asset {
            title: (default-to (get title asset) new-title),
            description: (default-to (get description asset) new-description),
            last-updated: block-height
          })
        )
        (ok true)
      )
      (err u404)
    )
  )
)

(define-public (transfer-ip-asset (asset-id uint) (recipient principal))
  (let ((caller tx-sender))
    (match (nft-get-owner? ip-asset asset-id)
      owner (begin
        (asserts! (is-eq caller owner) (err u403))
        (try! (nft-transfer? ip-asset asset-id caller recipient))
        (match (map-get? ip-assets { asset-id: asset-id })
          asset (begin
            (map-set ip-assets
              { asset-id: asset-id }
              (merge asset {
                owner: recipient,
                last-updated: block-height
              })
            )
            (ok true)
          )
          (err u404)
        )
      )
      (err u404)
    )
  )
)

(define-read-only (get-ip-asset (asset-id uint))
  (map-get? ip-assets { asset-id: asset-id })
)

(define-read-only (get-ip-asset-owner (asset-id uint))
  (nft-get-owner? ip-asset asset-id)
)

