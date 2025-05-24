;; Agency Verification Contract
;; Validates and manages government entities

;; Data Variables
(define-data-var contract-owner principal tx-sender)

;; Data Maps
(define-map agencies
  { agency-id: uint }
  {
    name: (string-ascii 100),
    jurisdiction: (string-ascii 50),
    contact-email: (string-ascii 100),
    verified: bool,
    verification-date: uint,
    verifier: principal
  }
)

(define-map agency-counter principal uint)

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-AGENCY-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-VERIFIED (err u102))

;; Private Functions
(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner))
)

;; Public Functions
(define-public (register-agency (name (string-ascii 100)) (jurisdiction (string-ascii 50)) (contact-email (string-ascii 100)))
  (let
    (
      (agency-id (+ (default-to u0 (map-get? agency-counter tx-sender)) u1))
    )
    (map-set agency-counter tx-sender agency-id)
    (map-set agencies
      { agency-id: agency-id }
      {
        name: name,
        jurisdiction: jurisdiction,
        contact-email: contact-email,
        verified: false,
        verification-date: u0,
        verifier: tx-sender
      }
    )
    (ok agency-id)
  )
)

(define-public (verify-agency (agency-id uint))
  (if (is-contract-owner)
    (match (map-get? agencies { agency-id: agency-id })
      agency-data
      (if (get verified agency-data)
        ERR-ALREADY-VERIFIED
        (begin
          (map-set agencies
            { agency-id: agency-id }
            (merge agency-data {
              verified: true,
              verification-date: block-height,
              verifier: tx-sender
            })
          )
          (ok true)
        )
      )
      ERR-AGENCY-NOT-FOUND
    )
    ERR-NOT-AUTHORIZED
  )
)

;; Read-only Functions
(define-read-only (get-agency (agency-id uint))
  (map-get? agencies { agency-id: agency-id })
)

(define-read-only (is-agency-verified (agency-id uint))
  (match (map-get? agencies { agency-id: agency-id })
    agency-data (get verified agency-data)
    false
  )
)
