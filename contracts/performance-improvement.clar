;; Performance Improvement Contract
;; Measures and tracks service enhancements

;; Data Maps
(define-map performance-metrics
  { service-id: uint, metric-period: uint }
  {
    response-time: uint,
    completion-rate: uint,
    user-satisfaction: uint,
    error-rate: uint,
    recorded-by: principal,
    timestamp: uint
  }
)

(define-map improvement-goals
  { service-id: uint }
  {
    target-response-time: uint,
    target-completion-rate: uint,
    target-satisfaction: uint,
    target-error-rate: uint,
    deadline: uint,
    set-by: principal
  }
)

;; Constants
(define-constant ERR-INVALID-METRICS (err u400))
(define-constant ERR-GOAL-NOT-FOUND (err u401))

;; Public Functions
(define-public (record-performance-metrics
  (service-id uint)
  (metric-period uint)
  (response-time uint)
  (completion-rate uint)
  (user-satisfaction uint)
  (error-rate uint)
)
  (if (and (<= completion-rate u100) (<= user-satisfaction u5) (<= error-rate u100))
    (begin
      (map-set performance-metrics
        { service-id: service-id, metric-period: metric-period }
        {
          response-time: response-time,
          completion-rate: completion-rate,
          user-satisfaction: user-satisfaction,
          error-rate: error-rate,
          recorded-by: tx-sender,
          timestamp: block-height
        }
      )
      (ok true)
    )
    ERR-INVALID-METRICS
  )
)

(define-public (set-improvement-goals
  (service-id uint)
  (target-response-time uint)
  (target-completion-rate uint)
  (target-satisfaction uint)
  (target-error-rate uint)
  (deadline uint)
)
  (begin
    (map-set improvement-goals
      { service-id: service-id }
      {
        target-response-time: target-response-time,
        target-completion-rate: target-completion-rate,
        target-satisfaction: target-satisfaction,
        target-error-rate: target-error-rate,
        deadline: deadline,
        set-by: tx-sender
      }
    )
    (ok true)
  )
)

;; Read-only Functions
(define-read-only (get-performance-metrics (service-id uint) (metric-period uint))
  (map-get? performance-metrics { service-id: service-id, metric-period: metric-period })
)

(define-read-only (get-improvement-goals (service-id uint))
  (map-get? improvement-goals { service-id: service-id })
)

(define-read-only (check-goal-achievement (service-id uint) (metric-period uint))
  (match (map-get? improvement-goals { service-id: service-id })
    goals
    (match (map-get? performance-metrics { service-id: service-id, metric-period: metric-period })
      metrics
      (ok {
        response-time-met: (<= (get response-time metrics) (get target-response-time goals)),
        completion-rate-met: (>= (get completion-rate metrics) (get target-completion-rate goals)),
        satisfaction-met: (>= (get user-satisfaction metrics) (get target-satisfaction goals)),
        error-rate-met: (<= (get error-rate metrics) (get target-error-rate goals))
      })
      (err u403) ;; Metrics not found
    )
    ERR-GOAL-NOT-FOUND
  )
)
