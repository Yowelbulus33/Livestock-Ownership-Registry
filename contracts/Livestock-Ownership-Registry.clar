(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_LIVESTOCK_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_REGISTERED (err u102))
(define-constant ERR_INVALID_TRANSFER (err u103))
(define-constant ERR_INVALID_SPECIES (err u104))
(define-constant ERR_INVALID_BREED (err u105))
(define-constant ERR_INVALID_OWNER (err u106))
(define-constant ERR_TRANSFER_TO_SELF (err u107))
(define-constant ERR_PENDING_TRANSFER (err u108))
(define-constant ERR_NO_PENDING_TRANSFER (err u109))
(define-constant ERR_INVALID_VERIFIER (err u110))
(define-constant ERR_BREEDING_RECORD_EXISTS (err u111))
(define-constant ERR_INVALID_PARENT (err u112))
(define-constant ERR_SAME_GENDER_BREEDING (err u113))
(define-constant ERR_INSURANCE_NOT_FOUND (err u114))
(define-constant ERR_INSURANCE_EXPIRED (err u115))
(define-constant ERR_CLAIM_EXISTS (err u116))
(define-constant ERR_INVALID_COVERAGE_AMOUNT (err u117))
(define-constant ERR_INVALID_CLAIM_AMOUNT (err u118))
(define-constant ERR_CLAIM_NOT_FOUND (err u119))

(define-data-var livestock-id-counter uint u0)
(define-data-var verification-id-counter uint u0)
(define-data-var breeding-record-counter uint u0)
(define-data-var contract-paused bool false)
(define-data-var insurance-policy-counter uint u0)
(define-data-var insurance-claim-counter uint u0)

(define-map livestock-registry
    { livestock-id: uint }
    {
        owner: principal,
        species: (string-ascii 50),
        breed: (string-ascii 50),
        age: uint,
        gender: (string-ascii 10),
        color: (string-ascii 50),
        weight: uint,
        health-status: (string-ascii 20),
        location: (string-ascii 100),
        registration-date: uint,
        last-updated: uint,
        verified: bool,
        active: bool,
    }
)

(define-map pending-transfers
    { livestock-id: uint }
    {
        from: principal,
        to: principal,
        transfer-date: uint,
        reason: (string-ascii 200),
    }
)

(define-map owner-livestock
    { owner: principal }
    { livestock-ids: (list 1000 uint) }
)

(define-map livestock-history
    {
        livestock-id: uint,
        sequence: uint,
    }
    {
        previous-owner: principal,
        new-owner: principal,
        transfer-date: uint,
        reason: (string-ascii 200),
    }
)

(define-map authorized-verifiers
    { verifier: principal }
    { active: bool }
)

(define-map verification-records
    { verification-id: uint }
    {
        livestock-id: uint,
        verifier: principal,
        verification-date: uint,
        status: (string-ascii 20),
        notes: (string-ascii 500),
    }
)

(define-map breeding-records
    { breeding-id: uint }
    {
        offspring-id: uint,
        sire-id: uint,
        dam-id: uint,
        breeding-date: uint,
        birth-date: uint,
        breeder: principal,
        breeding-method: (string-ascii 50),
        notes: (string-ascii 300),
    }
)

(define-map livestock-offspring
    { parent-id: uint }
    { offspring-ids: (list 100 uint) }
)

(define-map insurance-policies
    { policy-id: uint }
    {
        livestock-id: uint,
        policy-holder: principal,
        insurance-provider: (string-ascii 100),
        coverage-amount: uint,
        premium-amount: uint,
        policy-start: uint,
        policy-end: uint,
        coverage-type: (string-ascii 50),
        premium-paid: bool,
        active: bool,
    }
)

(define-map insurance-claims
    { claim-id: uint }
    {
        policy-id: uint,
        livestock-id: uint,
        claimant: principal,
        claim-amount: uint,
        claim-date: uint,
        incident-date: uint,
        claim-reason: (string-ascii 300),
        claim-status: (string-ascii 20),
        approved-amount: uint,
        processed-date: (optional uint),
    }
)

(define-map livestock-insurance
    { livestock-id: uint }
    { policy-ids: (list 10 uint) }
)

(define-public (register-livestock
        (species (string-ascii 50))
        (breed (string-ascii 50))
        (age uint)
        (gender (string-ascii 10))
        (color (string-ascii 50))
        (weight uint)
        (health-status (string-ascii 20))
        (location (string-ascii 100))
    )
    (let ((livestock-id (+ (var-get livestock-id-counter) u1)))
        (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
        (asserts! (> (len species) u0) ERR_INVALID_SPECIES)
        (asserts! (> (len breed) u0) ERR_INVALID_BREED)
        (asserts!
            (is-none (map-get? livestock-registry { livestock-id: livestock-id }))
            ERR_ALREADY_REGISTERED
        )

        (map-set livestock-registry { livestock-id: livestock-id } {
            owner: tx-sender,
            species: species,
            breed: breed,
            age: age,
            gender: gender,
            color: color,
            weight: weight,
            health-status: health-status,
            location: location,
            registration-date: stacks-block-height,
            last-updated: stacks-block-height,
            verified: false,
            active: true,
        })

        (let ((current-livestock (default-to (list)
                (get livestock-ids
                    (map-get? owner-livestock { owner: tx-sender })
                ))))
            (map-set owner-livestock { owner: tx-sender } { livestock-ids: (unwrap! (as-max-len? (append current-livestock livestock-id) u1000)
                ERR_UNAUTHORIZED
            ) }
            )
        )

        (var-set livestock-id-counter livestock-id)
        (ok livestock-id)
    )
)

(define-public (initiate-transfer
        (livestock-id uint)
        (new-owner principal)
        (reason (string-ascii 200))
    )
    (let ((livestock (unwrap! (map-get? livestock-registry { livestock-id: livestock-id })
            ERR_LIVESTOCK_NOT_FOUND
        )))
        (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
        (asserts! (is-eq (get owner livestock) tx-sender) ERR_UNAUTHORIZED)
        (asserts! (not (is-eq tx-sender new-owner)) ERR_TRANSFER_TO_SELF)
        (asserts! (get active livestock) ERR_INVALID_TRANSFER)
        (asserts!
            (is-none (map-get? pending-transfers { livestock-id: livestock-id }))
            ERR_PENDING_TRANSFER
        )

        (map-set pending-transfers { livestock-id: livestock-id } {
            from: tx-sender,
            to: new-owner,
            transfer-date: stacks-block-height,
            reason: reason,
        })

        (ok true)
    )
)

(define-public (accept-transfer (livestock-id uint))
    (let (
            (transfer (unwrap! (map-get? pending-transfers { livestock-id: livestock-id })
                ERR_NO_PENDING_TRANSFER
            ))
            (livestock (unwrap! (map-get? livestock-registry { livestock-id: livestock-id })
                ERR_LIVESTOCK_NOT_FOUND
            ))
        )
        (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
        (asserts! (is-eq (get to transfer) tx-sender) ERR_UNAUTHORIZED)
        (asserts! (get active livestock) ERR_INVALID_TRANSFER)

        (let ((history-sequence (get-transfer-history-count livestock-id)))
            (map-set livestock-history {
                livestock-id: livestock-id,
                sequence: history-sequence,
            } {
                previous-owner: (get from transfer),
                new-owner: tx-sender,
                transfer-date: stacks-block-height,
                reason: (get reason transfer),
            })
        )

        (map-set livestock-registry { livestock-id: livestock-id }
            (merge livestock {
                owner: tx-sender,
                last-updated: stacks-block-height,
                verified: false,
            })
        )

        (remove-livestock-from-owner (get from transfer) livestock-id)
        (add-livestock-to-owner tx-sender livestock-id)

        (map-delete pending-transfers { livestock-id: livestock-id })
        (ok true)
    )
)

(define-public (cancel-transfer (livestock-id uint))
    (let ((transfer (unwrap! (map-get? pending-transfers { livestock-id: livestock-id })
            ERR_NO_PENDING_TRANSFER
        )))
        (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
        (asserts! (is-eq (get from transfer) tx-sender) ERR_UNAUTHORIZED)

        (map-delete pending-transfers { livestock-id: livestock-id })
        (ok true)
    )
)

(define-public (update-livestock-info
        (livestock-id uint)
        (age uint)
        (weight uint)
        (health-status (string-ascii 20))
        (location (string-ascii 100))
    )
    (let ((livestock (unwrap! (map-get? livestock-registry { livestock-id: livestock-id })
            ERR_LIVESTOCK_NOT_FOUND
        )))
        (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
        (asserts! (is-eq (get owner livestock) tx-sender) ERR_UNAUTHORIZED)
        (asserts! (get active livestock) ERR_INVALID_TRANSFER)

        (map-set livestock-registry { livestock-id: livestock-id }
            (merge livestock {
                age: age,
                weight: weight,
                health-status: health-status,
                location: location,
                last-updated: stacks-block-height,
            })
        )

        (ok true)
    )
)

(define-public (deactivate-livestock (livestock-id uint))
    (let ((livestock (unwrap! (map-get? livestock-registry { livestock-id: livestock-id })
            ERR_LIVESTOCK_NOT_FOUND
        )))
        (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
        (asserts! (is-eq (get owner livestock) tx-sender) ERR_UNAUTHORIZED)
        (asserts! (get active livestock) ERR_INVALID_TRANSFER)

        (map-set livestock-registry { livestock-id: livestock-id }
            (merge livestock {
                active: false,
                last-updated: stacks-block-height,
            })
        )

        (ok true)
    )
)

(define-public (add-verifier (verifier principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)

        (map-set authorized-verifiers { verifier: verifier } { active: true })

        (ok true)
    )
)

(define-public (remove-verifier (verifier principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)

        (map-set authorized-verifiers { verifier: verifier } { active: false })

        (ok true)
    )
)

(define-public (verify-livestock
        (livestock-id uint)
        (status (string-ascii 20))
        (notes (string-ascii 500))
    )
    (let (
            (livestock (unwrap! (map-get? livestock-registry { livestock-id: livestock-id })
                ERR_LIVESTOCK_NOT_FOUND
            ))
            (verifier-status (unwrap! (map-get? authorized-verifiers { verifier: tx-sender })
                ERR_INVALID_VERIFIER
            ))
            (verification-id (+ (var-get verification-id-counter) u1))
        )
        (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
        (asserts! (get active verifier-status) ERR_INVALID_VERIFIER)
        (asserts! (get active livestock) ERR_INVALID_TRANSFER)

        (map-set verification-records { verification-id: verification-id } {
            livestock-id: livestock-id,
            verifier: tx-sender,
            verification-date: stacks-block-height,
            status: status,
            notes: notes,
        })

        (map-set livestock-registry { livestock-id: livestock-id }
            (merge livestock {
                verified: true,
                last-updated: stacks-block-height,
            })
        )

        (var-set verification-id-counter verification-id)
        (ok verification-id)
    )
)

(define-public (pause-contract)
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (var-set contract-paused true)
        (ok true)
    )
)

(define-public (unpause-contract)
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (var-set contract-paused false)
        (ok true)
    )
)

(define-public (record-breeding
        (offspring-id uint)
        (sire-id uint)
        (dam-id uint)
        (breeding-date uint)
        (birth-date uint)
        (breeding-method (string-ascii 50))
        (notes (string-ascii 300))
    )
    (let (
            (breeding-id (+ (var-get breeding-record-counter) u1))
            (offspring (unwrap! (map-get? livestock-registry { livestock-id: offspring-id })
                ERR_LIVESTOCK_NOT_FOUND
            ))
            (sire (unwrap! (map-get? livestock-registry { livestock-id: sire-id })
                ERR_INVALID_PARENT
            ))
            (dam (unwrap! (map-get? livestock-registry { livestock-id: dam-id })
                ERR_INVALID_PARENT
            ))
        )
        (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
        (asserts! (is-eq (get owner offspring) tx-sender) ERR_UNAUTHORIZED)
        (asserts! (get active offspring) ERR_INVALID_TRANSFER)
        (asserts! (get active sire) ERR_INVALID_PARENT)
        (asserts! (get active dam) ERR_INVALID_PARENT)
        (asserts! (not (is-eq (get gender sire) (get gender dam)))
            ERR_SAME_GENDER_BREEDING
        )
        (asserts! (< breeding-date birth-date) ERR_INVALID_TRANSFER)
        (asserts! (is-none (get-breeding-record-by-offspring offspring-id))
            ERR_BREEDING_RECORD_EXISTS
        )

        (map-set breeding-records { breeding-id: breeding-id } {
            offspring-id: offspring-id,
            sire-id: sire-id,
            dam-id: dam-id,
            breeding-date: breeding-date,
            birth-date: birth-date,
            breeder: tx-sender,
            breeding-method: breeding-method,
            notes: notes,
        })

        (add-offspring-to-parent sire-id offspring-id)
        (add-offspring-to-parent dam-id offspring-id)

        (var-set breeding-record-counter breeding-id)
        (ok breeding-id)
    )
)

(define-public (register-insurance-policy
        (livestock-id uint)
        (insurance-provider (string-ascii 100))
        (coverage-amount uint)
        (premium-amount uint)
        (policy-duration uint)
        (coverage-type (string-ascii 50))
    )
    (let (
            (policy-id (+ (var-get insurance-policy-counter) u1))
            (livestock (unwrap! (map-get? livestock-registry { livestock-id: livestock-id })
                ERR_LIVESTOCK_NOT_FOUND
            ))
        )
        (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
        (asserts! (is-eq (get owner livestock) tx-sender) ERR_UNAUTHORIZED)
        (asserts! (get active livestock) ERR_INVALID_TRANSFER)
        (asserts! (> coverage-amount u0) ERR_INVALID_COVERAGE_AMOUNT)
        (asserts! (> premium-amount u0) ERR_INVALID_COVERAGE_AMOUNT)
        (asserts! (> policy-duration u0) ERR_INVALID_COVERAGE_AMOUNT)
        (asserts! (> (len insurance-provider) u0) ERR_INVALID_COVERAGE_AMOUNT)
        (asserts! (> (len coverage-type) u0) ERR_INVALID_COVERAGE_AMOUNT)

        (map-set insurance-policies { policy-id: policy-id } {
            livestock-id: livestock-id,
            policy-holder: tx-sender,
            insurance-provider: insurance-provider,
            coverage-amount: coverage-amount,
            premium-amount: premium-amount,
            policy-start: stacks-block-height,
            policy-end: (+ stacks-block-height policy-duration),
            coverage-type: coverage-type,
            premium-paid: false,
            active: true,
        })

        (let ((current-policies (default-to (list)
                (get policy-ids
                    (map-get? livestock-insurance { livestock-id: livestock-id })
                ))))
            (map-set livestock-insurance { livestock-id: livestock-id } { policy-ids: (unwrap! (as-max-len? (append current-policies policy-id) u10)
                ERR_UNAUTHORIZED
            ) }
            )
        )

        (var-set insurance-policy-counter policy-id)
        (ok policy-id)
    )
)

(define-public (pay-insurance-premium (policy-id uint))
    (let ((policy (unwrap! (map-get? insurance-policies { policy-id: policy-id })
            ERR_INSURANCE_NOT_FOUND
        )))
        (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
        (asserts! (is-eq (get policy-holder policy) tx-sender) ERR_UNAUTHORIZED)
        (asserts! (get active policy) ERR_INSURANCE_EXPIRED)
        (asserts! (< stacks-block-height (get policy-end policy))
            ERR_INSURANCE_EXPIRED
        )

        (map-set insurance-policies { policy-id: policy-id }
            (merge policy { premium-paid: true })
        )

        (ok true)
    )
)

(define-public (file-insurance-claim
        (policy-id uint)
        (claim-amount uint)
        (incident-date uint)
        (claim-reason (string-ascii 300))
    )
    (let (
            (claim-id (+ (var-get insurance-claim-counter) u1))
            (policy (unwrap! (map-get? insurance-policies { policy-id: policy-id })
                ERR_INSURANCE_NOT_FOUND
            ))
            (livestock (unwrap!
                (map-get? livestock-registry { livestock-id: (get livestock-id policy) })
                ERR_LIVESTOCK_NOT_FOUND
            ))
        )
        (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
        (asserts! (is-eq (get policy-holder policy) tx-sender) ERR_UNAUTHORIZED)
        (asserts! (get active policy) ERR_INSURANCE_EXPIRED)
        (asserts! (get premium-paid policy) ERR_INSURANCE_EXPIRED)
        (asserts! (< stacks-block-height (get policy-end policy))
            ERR_INSURANCE_EXPIRED
        )
        (asserts! (> claim-amount u0) ERR_INVALID_CLAIM_AMOUNT)
        (asserts! (<= claim-amount (get coverage-amount policy))
            ERR_INVALID_CLAIM_AMOUNT
        )
        (asserts! (<= incident-date stacks-block-height) ERR_INVALID_CLAIM_AMOUNT)
        (asserts! (>= incident-date (get policy-start policy))
            ERR_INVALID_CLAIM_AMOUNT
        )
        (asserts! (> (len claim-reason) u0) ERR_INVALID_CLAIM_AMOUNT)

        (map-set insurance-claims { claim-id: claim-id } {
            policy-id: policy-id,
            livestock-id: (get livestock-id policy),
            claimant: tx-sender,
            claim-amount: claim-amount,
            claim-date: stacks-block-height,
            incident-date: incident-date,
            claim-reason: claim-reason,
            claim-status: "pending",
            approved-amount: u0,
            processed-date: none,
        })

        (var-set insurance-claim-counter claim-id)
        (ok claim-id)
    )
)

(define-public (process-insurance-claim
        (claim-id uint)
        (approved-amount uint)
        (claim-status (string-ascii 20))
    )
    (let ((claim (unwrap! (map-get? insurance-claims { claim-id: claim-id })
            ERR_CLAIM_NOT_FOUND
        )))
        (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (is-eq (get claim-status claim) "pending") ERR_CLAIM_NOT_FOUND)
        (asserts! (<= approved-amount (get claim-amount claim))
            ERR_INVALID_CLAIM_AMOUNT
        )
        (asserts! (> (len claim-status) u0) ERR_INVALID_CLAIM_AMOUNT)

        (map-set insurance-claims { claim-id: claim-id }
            (merge claim {
                approved-amount: approved-amount,
                claim-status: claim-status,
                processed-date: (some stacks-block-height),
            })
        )

        (ok true)
    )
)

(define-public (cancel-insurance-policy (policy-id uint))
    (let ((policy (unwrap! (map-get? insurance-policies { policy-id: policy-id })
            ERR_INSURANCE_NOT_FOUND
        )))
        (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
        (asserts! (is-eq (get policy-holder policy) tx-sender) ERR_UNAUTHORIZED)
        (asserts! (get active policy) ERR_INSURANCE_EXPIRED)

        (map-set insurance-policies { policy-id: policy-id }
            (merge policy { active: false })
        )

        (ok true)
    )
)

(define-read-only (get-livestock-info (livestock-id uint))
    (map-get? livestock-registry { livestock-id: livestock-id })
)

(define-read-only (get-pending-transfer (livestock-id uint))
    (map-get? pending-transfers { livestock-id: livestock-id })
)

(define-read-only (get-owner-livestock (owner principal))
    (map-get? owner-livestock { owner: owner })
)

(define-read-only (get-livestock-history
        (livestock-id uint)
        (sequence uint)
    )
    (map-get? livestock-history {
        livestock-id: livestock-id,
        sequence: sequence,
    })
)

(define-read-only (get-verification-record (verification-id uint))
    (map-get? verification-records { verification-id: verification-id })
)

(define-read-only (is-authorized-verifier (verifier principal))
    (default-to { active: false }
        (map-get? authorized-verifiers { verifier: verifier })
    )
)

(define-read-only (get-current-livestock-id)
    (var-get livestock-id-counter)
)

(define-read-only (get-current-verification-id)
    (var-get verification-id-counter)
)

(define-read-only (is-contract-paused)
    (var-get contract-paused)
)

(define-read-only (get-breeding-record (breeding-id uint))
    (map-get? breeding-records { breeding-id: breeding-id })
)

(define-read-only (get-breeding-record-by-offspring (offspring-id uint))
    (if (> offspring-id u0)
        (map-get? breeding-records { breeding-id: offspring-id })
        none
    )
)

(define-read-only (get-livestock-offspring (parent-id uint))
    (map-get? livestock-offspring { parent-id: parent-id })
)

(define-read-only (get-current-breeding-id)
    (var-get breeding-record-counter)
)

(define-read-only (verify-ownership
        (livestock-id uint)
        (claimed-owner principal)
    )
    (match (map-get? livestock-registry { livestock-id: livestock-id })
        livestock (is-eq (get owner livestock) claimed-owner)
        false
    )
)

(define-read-only (get-insurance-policy (policy-id uint))
    (map-get? insurance-policies { policy-id: policy-id })
)

(define-read-only (get-insurance-claim (claim-id uint))
    (map-get? insurance-claims { claim-id: claim-id })
)

(define-read-only (get-livestock-insurance-policies (livestock-id uint))
    (map-get? livestock-insurance { livestock-id: livestock-id })
)

(define-read-only (get-current-insurance-policy-id)
    (var-get insurance-policy-counter)
)

(define-read-only (get-current-insurance-claim-id)
    (var-get insurance-claim-counter)
)

(define-read-only (is-insurance-policy-active (policy-id uint))
    (match (map-get? insurance-policies { policy-id: policy-id })
        policy (and
            (get active policy)
            (< stacks-block-height (get policy-end policy))
            (get premium-paid policy)
        )
        false
    )
)

(define-read-only (get-policy-coverage-remaining (policy-id uint))
    (match (map-get? insurance-policies { policy-id: policy-id })
        policy (if (and (get active policy) (< stacks-block-height (get policy-end policy)))
            (some (- (get policy-end policy) stacks-block-height))
            none
        )
        none
    )
)

(define-private (get-transfer-history-count (livestock-id uint))
    (fold check-history-sequence
        (list
            u0             u1             u2             u3             u4
            u5             u6             u7             u8             u9
            u10             u11             u12             u13             u14
            u15             u16             u17             u18
            u19             u20
        )
        u0
    )
)

(define-private (check-history-sequence
        (sequence uint)
        (count uint)
    )
    (if (is-some (map-get? livestock-history {
            livestock-id: u0,
            sequence: sequence,
        }))
        (+ count u1)
        count
    )
)

(define-private (remove-livestock-from-owner
        (owner principal)
        (livestock-id uint)
    )
    (let ((current-livestock (default-to (list)
            (get livestock-ids (map-get? owner-livestock { owner: owner }))
        )))
        (map-set owner-livestock { owner: owner } { livestock-ids: (filter is-not-target-livestock current-livestock) })
    )
)

(define-private (add-livestock-to-owner
        (owner principal)
        (livestock-id uint)
    )
    (let ((current-livestock (default-to (list)
            (get livestock-ids (map-get? owner-livestock { owner: owner }))
        )))
        (map-set owner-livestock { owner: owner } { livestock-ids: (unwrap-panic (as-max-len? (append current-livestock livestock-id) u1000)) })
    )
)

(define-private (is-not-target-livestock (id uint))
    (not (is-eq id u0))
)

(define-private (add-offspring-to-parent
        (parent-id uint)
        (offspring-id uint)
    )
    (let ((current-offspring (default-to (list)
            (get offspring-ids
                (map-get? livestock-offspring { parent-id: parent-id })
            ))))
        (map-set livestock-offspring { parent-id: parent-id } { offspring-ids: (unwrap-panic (as-max-len? (append current-offspring offspring-id) u100)) })
    )
)
