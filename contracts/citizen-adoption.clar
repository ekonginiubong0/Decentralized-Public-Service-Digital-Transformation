;; Citizen Adoption Contract
;; Tracks digital service usage and citizen engagement

;; Data Maps
(define-map service-usage
  { service-id: uint, citizen: principal }
  {
    first-use-date: uint,
    total-uses: uint,
    last-use-date: uint,
    satisfaction-rating: uint
  }
)

(define-map citizen-profiles
  { citizen: principal }
  {
    registration-date: uint,
    total-services-used: uint,
    preferred-categories: (list 5 (string-ascii 50))
  }
)

;; Constants
(define-constant ERR-INVALID-RATING (err u300))
(define-constant ERR-CITIZEN-NOT-FOUND (err u301))

;; Public Functions
(define-public (register-citizen (preferred-categories (list 5 (string-ascii 50))))
  (begin
    (map-set citizen-profiles
      { citizen: tx-sender }
      {
        registration-date: block-height,
        total-services-used: u0,
        preferred-categories: preferred-categories
      }
    )
    (ok true)
  )
)

(define-public (record-service-usage (service-id uint))
  (let
    (
      (existing-usage (map-get? service-usage { service-id: service-id, citizen: tx-sender }))
    )
    (match existing-usage
      usage-data
      (map-set service-usage
        { service-id: service-id, citizen: tx-sender }
        (merge usage-data {
          total-uses: (+ (get total-uses usage-data) u1),
          last-use-date: block-height
        })
      )
      (map-set service-usage
        { service-id: service-id, citizen: tx-sender }
        {
          first-use-date: block-height,
          total-uses: u1,
          last-use-date: block-height,
          satisfaction-rating: u0
        }
      )
    )
    (ok true)
  )
)

(define-public (rate-service (service-id uint) (rating uint))
  (if (and (>= rating u1) (<= rating u5))
    (match (map-get? service-usage { service-id: service-id, citizen: tx-sender })
      usage-data
      (begin
        (map-set service-usage
          { service-id: service-id, citizen: tx-sender }
          (merge usage-data { satisfaction-rating: rating })
        )
        (ok true)
      )
      (err u302) ;; Must use service before rating
    )
    ERR-INVALID-RATING
  )
)

;; Read-only Functions
(define-read-only (get-citizen-usage (service-id uint) (citizen principal))
  (map-get? service-usage { service-id: service-id, citizen: citizen })
)

(define-read-only (get-citizen-profile (citizen principal))
  (map-get? citizen-profiles { citizen: citizen })
)
