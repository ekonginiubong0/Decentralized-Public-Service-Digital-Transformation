;; Service Digitization Contract
;; Records and manages digital service offerings

;; Data Maps
(define-map digital-services
  { service-id: uint }
  {
    agency-id: uint,
    name: (string-ascii 100),
    description: (string-ascii 500),
    category: (string-ascii 50),
    launch-date: uint,
    status: (string-ascii 20),
    creator: principal
  }
)

(define-map service-counter principal uint)

;; Constants
(define-constant ERR-SERVICE-NOT-FOUND (err u200))
(define-constant ERR-NOT-SERVICE-CREATOR (err u201))

;; Public Functions
(define-public (create-digital-service
  (agency-id uint)
  (name (string-ascii 100))
  (description (string-ascii 500))
  (category (string-ascii 50))
)
  (let
    (
      (service-id (+ (default-to u0 (map-get? service-counter tx-sender)) u1))
    )
    (map-set service-counter tx-sender service-id)
    (map-set digital-services
      { service-id: service-id }
      {
        agency-id: agency-id,
        name: name,
        description: description,
        category: category,
        launch-date: block-height,
        status: "active",
        creator: tx-sender
      }
    )
    (ok service-id)
  )
)

(define-public (update-service-status (service-id uint) (new-status (string-ascii 20)))
  (match (map-get? digital-services { service-id: service-id })
    service-data
    (if (is-eq tx-sender (get creator service-data))
      (begin
        (map-set digital-services
          { service-id: service-id }
          (merge service-data { status: new-status })
        )
        (ok true)
      )
      ERR-NOT-SERVICE-CREATOR
    )
    ERR-SERVICE-NOT-FOUND
  )
)

;; Read-only Functions
(define-read-only (get-digital-service (service-id uint))
  (map-get? digital-services { service-id: service-id })
)

(define-read-only (get-services-by-agency (agency-id uint))
  ;; In a real implementation, this would iterate through services
  ;; For simplicity, returning a placeholder
  (ok agency-id)
)
