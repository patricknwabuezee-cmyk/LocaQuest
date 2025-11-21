
;; Geotagged NFT Rewards Contract
;; Enhanced error handling and data validation

(define-non-fungible-token geotagged-nft uint)

;; Constants and Settings
(define-constant contract-owner tx-sender)
(define-constant min-distance u100)
(define-constant points-threshold u100)
(define-constant max-lat u90000000) ;; 90 degrees * 1M for precision
(define-constant max-long u180000000) ;; 180 degrees * 1M for precision
(define-constant max-locations u1000)
(define-constant max-points-per-activity u1000)

;; Error codes
(define-constant err-owner-only (err u100))
(define-constant err-already-completed (err u101))
(define-constant err-invalid-location (err u102))
(define-constant err-insufficient-points (err u103))
(define-constant err-invalid-coordinates (err u104))
(define-constant err-location-limit-exceeded (err u105))
(define-constant err-invalid-points (err u106))
(define-constant err-invalid-token-id (err u107))
(define-constant err-empty-name (err u108))
(define-constant err-empty-activity (err u109))
(define-constant err-nft-already-minted (err u110))
(define-constant err-zero-amount (err u111))
(define-constant err-self-transfer (err u112))
(define-constant err-invalid-user (err u113))
(define-constant err-location-not-found (err u114))
(define-constant err-zero-token-id (err u115))
(define-constant err-max-token-id (err u116))
(define-constant err-location-disabled (err u117))

;; Data Maps
(define-map locations 
    uint 
    { name: (string-ascii 50),
      lat: uint,
      long: uint,
      activity: (string-ascii 100),
      reward-points: uint }
)

(define-map user-completions 
    { user: principal, location-id: uint } 
    { completed: bool,
      timestamp: uint }
)

(define-map user-points principal uint)
(define-map location-count uint uint)
(define-map minted-nfts uint bool)
(define-map location-status uint bool)  ;; true if active, false if disabled

;; Helper Functions
(define-private (validate-coordinates (lat uint) (long uint))
    (and (<= lat max-lat)
         (<= long max-long))
)

(define-private (validate-location-data (name (string-ascii 50)) (activity (string-ascii 100)) (points uint))
    (and (not (is-eq name ""))
         (not (is-eq activity ""))
         (<= points max-points-per-activity))
)

(define-private (calculate-distance (lat1 uint) (long1 uint) (lat2 uint) (long2 uint))
    (let ((lat-diff (if (> lat2 lat1) 
                       (- lat2 lat1) 
                       (- lat1 lat2)))
          (long-diff (if (> long2 long1)
                        (- long2 long1)
                        (- long1 long2))))
        (+ (* lat-diff lat-diff) (* long-diff long-diff))
    )
)

(define-private (validate-token-id (token-id uint))
    (and (> token-id u0)
         (<= token-id u1000))  ;; Assuming max NFT ID is 1000
)

(define-private (validate-amount (amount uint))
    (> amount u0)
)

(define-private (validate-user (user principal))
    (and 
        (not (is-eq user tx-sender))
        (not (is-eq user contract-owner))
    )
)

(define-private (validate-location-active (location-id uint))
    (default-to true (map-get? location-status location-id))
)

;; Admin Functions
(define-public (add-location (id uint) (name (string-ascii 50)) (lat uint) (long uint) (activity (string-ascii 100)) (points uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (< (default-to u0 (map-get? location-count u0)) max-locations) err-location-limit-exceeded)
        (asserts! (validate-coordinates lat long) err-invalid-coordinates)
        (asserts! (validate-location-data name activity points) err-invalid-points)
        (asserts! (not (is-some (map-get? locations id))) err-location-not-found)
        
        (map-set location-status id true)
        (map-set location-count u0 (+ u1 (default-to u0 (map-get? location-count u0))))
        (ok (map-set locations id { 
            name: name,
            lat: lat, 
            long: long,
            activity: activity,
            reward-points: points
        }))
    )
)

(define-public (set-location-status (location-id uint) (active bool))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-some (map-get? locations location-id)) err-location-not-found)
        (ok (map-set location-status location-id active))
    )
)

;; Core Functions
(define-public (complete-activity (location-id uint) (user-lat uint) (user-long uint))
    (let ((location (unwrap! (map-get? locations location-id) err-invalid-location))
          (completion-key { user: tx-sender, location-id: location-id }))
        
        (asserts! (validate-coordinates user-lat user-long) err-invalid-coordinates)
        (asserts! (not (default-to false (get completed (map-get? user-completions completion-key)))) 
                 err-already-completed)
        (asserts! (validate-location-active location-id) err-location-disabled)
        (asserts! (<= (calculate-distance user-lat user-long 
                                        (get lat location) 
                                        (get long location)) 
                     min-distance)
                 err-invalid-location)
        
        (map-set user-completions 
            completion-key 
            { completed: true,
              timestamp: stacks-block-height }
        )
        
        (map-set user-points 
            tx-sender 
            (+ (default-to u0 (map-get? user-points tx-sender))
               (get reward-points location))
        )
        
        (ok true)
    )
)

(define-public (mint-nft (token-id uint))
    (let ((user-point-balance (default-to u0 (map-get? user-points tx-sender))))
        (asserts! (validate-token-id token-id) err-invalid-token-id)
        (asserts! (>= user-point-balance points-threshold) err-insufficient-points)
        (asserts! (not (default-to false (map-get? minted-nfts token-id))) err-nft-already-minted)
        
        (map-set user-points 
            tx-sender 
            (- user-point-balance points-threshold))
        
        (map-set minted-nfts token-id true)    
        (nft-mint? geotagged-nft token-id tx-sender)
    )
)

;; Points Transfer Function
(define-public (transfer-points (recipient principal) (amount uint))
    (let (
        (sender-balance (get-user-points tx-sender))
        (recipient-balance (get-user-points recipient))
    )
        (asserts! (validate-amount amount) err-zero-amount)
        (asserts! (validate-user recipient) err-invalid-user)
        (asserts! (>= sender-balance amount) err-insufficient-points)
        
        ;; Update sender balance
        (map-set user-points 
            tx-sender 
            (- sender-balance amount))
        
        ;; Update recipient balance
        (map-set user-points 
            recipient 
            (+ recipient-balance amount))
            
        (ok true)
    )
)

;; Read-only Functions
(define-read-only (get-location (id uint))
    (map-get? locations id)
)

(define-read-only (get-user-points (user principal))
    (default-to u0 (map-get? user-points user))
)

(define-read-only (get-completion-status (user principal) (location-id uint))
    (get completed (default-to 
        { completed: false, timestamp: u0 }
        (map-get? user-completions { user: user, location-id: location-id })))
)

(define-read-only (is-nft-minted (token-id uint))
    (default-to false (map-get? minted-nfts token-id))
)

(define-read-only (get-location-status (location-id uint))
    (default-to false (map-get? location-status location-id))
)

;; Get simplified user stats
(define-read-only (get-user-stats (user principal))
    (let (
        (total-points (get-user-points user))
    )
        (ok {
            points-balance: total-points,
            can-mint-nft: (>= total-points points-threshold)
        })
    )
)
