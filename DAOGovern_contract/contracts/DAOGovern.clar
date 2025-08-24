
;; title: DAOGovern
;; version: 1.0.0
;; summary: A decentralized autonomous organization governance smart contract
;; description: This contract implements a voting system for DAO governance including proposal creation, voting mechanisms, and execution

;; traits
;;

;; token definitions
;;

;; constants
;;
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-voted (err u102))
(define-constant err-voting-ended (err u103))
(define-constant err-voting-not-ended (err u104))
(define-constant err-insufficient-balance (err u105))
(define-constant err-proposal-not-active (err u106))
(define-constant err-proposal-already-executed (err u107))

;; Voting power threshold (minimum STX to vote)
(define-constant min-voting-power u1000000) ;; 1 STX in microstx

;; Proposal duration in blocks (approximately 1 week)
(define-constant proposal-duration u1008)

;; data vars
;;
(define-data-var proposal-id-nonce uint u0)

;; data maps
;;
;; Proposal data structure
(define-map proposals
  { proposal-id: uint }
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    proposer: principal,
    start-block: uint,
    end-block: uint,
    votes-for: uint,
    votes-against: uint,
    executed: bool,
    active: bool
  }
)

;; Track votes by user for each proposal
(define-map votes
  { proposal-id: uint, voter: principal }
  {
    vote: bool, ;; true for "yes", false for "no"
    voting-power: uint
  }
)

;; Track voting power (could be based on token holdings)
(define-map voting-power
  { voter: principal }
  { power: uint }
)

;; public functions
;;

;; Create a new proposal
(define-public (create-proposal (title (string-ascii 100)) (description (string-ascii 500)))
  (let
    (
      (new-proposal-id (+ (var-get proposal-id-nonce) u1))
      (start-block block-height)
      (end-block (+ block-height proposal-duration))
    )
    (begin
      ;; Check if user has minimum voting power
      (asserts! (>= (get-voting-power tx-sender) min-voting-power) err-insufficient-balance)
      
      ;; Store the proposal
      (map-set proposals
        { proposal-id: new-proposal-id }
        {
          title: title,
          description: description,
          proposer: tx-sender,
          start-block: start-block,
          end-block: end-block,
          votes-for: u0,
          votes-against: u0,
          executed: false,
          active: true
        }
      )
      
      ;; Update proposal ID nonce
      (var-set proposal-id-nonce new-proposal-id)
      
      ;; Print event
      (print {
        event: "proposal-created",
        proposal-id: new-proposal-id,
        proposer: tx-sender,
        title: title
      })
      
      (ok new-proposal-id)
    )
  )
)

;; Vote on a proposal
(define-public (vote-on-proposal (proposal-id uint) (vote bool))
  (let
    (
      (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) err-not-found))
      (voter-power (get-voting-power tx-sender))
    )
    (begin
      ;; Check if proposal exists and is active
      (asserts! (get active proposal) err-proposal-not-active)
      
      ;; Check if voting period is still active
      (asserts! (<= block-height (get end-block proposal)) err-voting-ended)
      
      ;; Check if user hasn't already voted
      (asserts! (is-none (map-get? votes { proposal-id: proposal-id, voter: tx-sender })) err-already-voted)
      
      ;; Check if user has minimum voting power
      (asserts! (>= voter-power min-voting-power) err-insufficient-balance)
      
      ;; Record the vote
      (map-set votes
        { proposal-id: proposal-id, voter: tx-sender }
        { vote: vote, voting-power: voter-power }
      )
      
      ;; Update proposal vote counts
      (map-set proposals
        { proposal-id: proposal-id }
        (merge proposal {
          votes-for: (if vote (+ (get votes-for proposal) voter-power) (get votes-for proposal)),
          votes-against: (if vote (get votes-against proposal) (+ (get votes-against proposal) voter-power))
        })
      )
      
      ;; Print event
      (print {
        event: "vote-cast",
        proposal-id: proposal-id,
        voter: tx-sender,
        vote: vote,
        voting-power: voter-power
      })
      
      (ok true)
    )
  )
)

;; Execute a proposal (can be called by anyone after voting period ends)
(define-public (execute-proposal (proposal-id uint))
  (let
    (
      (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) err-not-found))
    )
    (begin
      ;; Check if proposal exists and is active
      (asserts! (get active proposal) err-proposal-not-active)
      
      ;; Check if voting period has ended
      (asserts! (> block-height (get end-block proposal)) err-voting-not-ended)
      
      ;; Check if not already executed
      (asserts! (not (get executed proposal)) err-proposal-already-executed)
      
      ;; Mark as executed
      (map-set proposals
        { proposal-id: proposal-id }
        (merge proposal { executed: true })
      )
      
      ;; Print event with results
      (print {
        event: "proposal-executed",
        proposal-id: proposal-id,
        votes-for: (get votes-for proposal),
        votes-against: (get votes-against proposal),
        passed: (> (get votes-for proposal) (get votes-against proposal))
      })
      
      (ok (> (get votes-for proposal) (get votes-against proposal)))
    )
  )
)

;; Set voting power for a user (only contract owner can call this)
(define-public (set-voting-power (user principal) (power uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set voting-power { voter: user } { power: power })
    (ok true)
  )
)

;; Cancel a proposal (only proposer or contract owner can call this)
(define-public (cancel-proposal (proposal-id uint))
  (let
    (
      (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) err-not-found))
    )
    (begin
      ;; Check if caller is proposer or contract owner
      (asserts! (or (is-eq tx-sender (get proposer proposal)) (is-eq tx-sender contract-owner)) err-owner-only)
      
      ;; Check if proposal is active and not executed
      (asserts! (get active proposal) err-proposal-not-active)
      (asserts! (not (get executed proposal)) err-proposal-already-executed)
      
      ;; Mark as inactive
      (map-set proposals
        { proposal-id: proposal-id }
        (merge proposal { active: false })
      )
      
      ;; Print event
      (print {
        event: "proposal-cancelled",
        proposal-id: proposal-id,
        cancelled-by: tx-sender
      })
      
      (ok true)
    )
  )
)

;; read only functions
;;

;; Get proposal details
(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals { proposal-id: proposal-id })
)

;; Get vote details for a specific voter and proposal
(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? votes { proposal-id: proposal-id, voter: voter })
)

;; Get voting power for a user
(define-read-only (get-voting-power (user principal))
  (default-to u0 (get power (map-get? voting-power { voter: user })))
)

;; Get current proposal ID nonce
(define-read-only (get-current-proposal-id)
  (var-get proposal-id-nonce)
)

;; Check if a proposal has passed (only callable after voting period)
(define-read-only (has-proposal-passed (proposal-id uint))
  (match (map-get? proposals { proposal-id: proposal-id })
    proposal (ok (> (get votes-for proposal) (get votes-against proposal)))
    err-not-found
  )
)

;; Get proposal status
(define-read-only (get-proposal-status (proposal-id uint))
  (match (map-get? proposals { proposal-id: proposal-id })
    proposal (ok {
      active: (get active proposal),
      executed: (get executed proposal),
      voting-ended: (> block-height (get end-block proposal)),
      votes-for: (get votes-for proposal),
      votes-against: (get votes-against proposal),
      total-votes: (+ (get votes-for proposal) (get votes-against proposal))
    })
    err-not-found
  )
)

;; private functions
;;

;; Initialize voting power based on STX balance (could be called during deployment)
(define-private (initialize-voting-power (user principal))
  (let
    (
      (stx-balance (stx-get-balance user))
    )
    (map-set voting-power { voter: user } { power: stx-balance })
  )
)

