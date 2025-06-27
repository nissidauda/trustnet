;; --------------------------------------------------
;; Contract: TrustNet
;; Purpose: Decentralized provider registry with stake-based challenges and voting
;; --------------------------------------------------

(define-data-var next-id uint u0)
(define-data-var contract-admin principal tx-sender)

(define-map providers
  uint
  {
    submitted-by: principal,
    name: (string-utf8 64),
    contact: (string-utf8 64),
    description: (string-utf8 128),
    stake: uint,
    challenged: bool,
    approved: bool
  }
)

(define-map challenges
  uint
  {
    challenger: principal,
    stake: uint,
    votes-for: uint,
    votes-against: uint,
    resolved: bool
  }
)

(define-map votes
  { provider-id: uint, voter: principal }
  { vote-for: bool, amount: uint }
)

;; === Submit provider ===
(define-public (submit-provider (name (string-utf8 64)) (contact (string-utf8 64)) (description (string-utf8 128)) (stake uint))
  (begin
    (asserts! (> stake u0) (err u100))
    (let ((id (var-get next-id)))
      (try! (stx-transfer? stake tx-sender (as-contract tx-sender)))
      (map-set providers id {
        submitted-by: tx-sender,
        name: name,
        contact: contact,
        description: description,
        stake: stake,
        challenged: false,
        approved: true
      })
      (var-set next-id (+ id u1))
      (ok id)
    )
  )
)

;; === Update provider info ===
(define-public (update-provider (id uint) (name (string-utf8 64)) (contact (string-utf8 64)) (description (string-utf8 128)))
  (match (map-get? providers id)
    p
    (begin
      (asserts! (is-eq tx-sender (get submitted-by p)) (err u110))
      (map-set providers id (merge p {
        name: name,
        contact: contact,
        description: description
      }))
      (ok true)
    )
    (err u103)
  )
)

;; === Challenge provider ===
(define-public (challenge-provider (id uint) (stake uint))
  (let ((p (map-get? providers id)))
    (match p
      pdata
      (begin
        (asserts! (not (get challenged pdata)) (err u101))
        (asserts! (> stake u0) (err u102))
        (try! (stx-transfer? stake tx-sender (as-contract tx-sender)))
        (map-set providers id (merge pdata { challenged: true }))
        (map-set challenges id {
          challenger: tx-sender,
          stake: stake,
          votes-for: u0,
          votes-against: u0,
          resolved: false
        })
        (ok true)
      )
      (err u103)
    )
  )
)

;; === Vote ===
(define-public (vote (id uint) (vote-for bool) (amount uint))
  (match (map-get? challenges id)
    c
    (begin
      (asserts! (not (get resolved c)) (err u104))
      (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
      (if vote-for
          (map-set challenges id (merge c { votes-for: (+ (get votes-for c) amount) }))
          (map-set challenges id (merge c { votes-against: (+ (get votes-against c) amount) }))
      )
      (map-set votes { provider-id: id, voter: tx-sender } { vote-for: vote-for, amount: amount })
      (ok true)
    )
    (err u105)
  )
)

;; === Resolve ===
(define-public (resolve (id uint))
  (let ((p (map-get? providers id))
        (c (map-get? challenges id)))
    (match p
      pdata
      (match c
        cdata
        (begin
          (asserts! (not (get resolved cdata)) (err u106))
          (map-set challenges id (merge cdata { resolved: true }))
          (if (> (get votes-for cdata) (get votes-against cdata))
              (begin
                (map-set providers id (merge pdata { approved: false }))
                (try! (stx-transfer? (+ (get stake pdata) (get stake cdata)) (as-contract tx-sender) (get challenger cdata)))
              )
              (try! (stx-transfer? (get stake cdata) (as-contract tx-sender) (get submitted-by pdata)))
          )
          (ok true)
        )
        (err u107)
      )
      (err u108)
    )
  )
)

;; === Admin remove ===
(define-public (admin-remove (id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-admin)) (err u111))
    (map-delete providers id)
    (ok true)
  )
)

;; === Withdraw stake (after resolved) ===
(define-public (withdraw-stake (id uint))
  (match (map-get? challenges id)
    c
    (begin
      (asserts! (get resolved c) (err u112))
      (ok true) ;; Already distributed during resolve; function placeholder or optional secondary logic
    )
    (err u105)
  )
)

;; === Admin transfer ===
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-admin)) (err u111))
    (var-set contract-admin new-admin)
    (ok true)
  )
)

;; === Get provider ===
(define-read-only (get-provider (id uint))
  (ok (map-get? providers id))
)

;; === Is approved ===
(define-read-only (is-approved (id uint))
  (match (map-get? providers id)
    p (ok (get approved p))
    (err u109)
  )
)

;; === Is challenged ===
(define-read-only (is-challenged (id uint))
  (match (map-get? providers id)
    p (ok (get challenged p))
    (err u109)
  )
)

;; === Get provider count ===
(define-read-only (get-provider-count)
  (ok (var-get next-id))
)
