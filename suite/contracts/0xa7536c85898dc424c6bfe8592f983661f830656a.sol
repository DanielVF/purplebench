// Flattened verified source for Purplebench.
// Compilation target: src/contracts/core/StrategyManager.sol:StrategyManager
// Pragmas and imports were removed for single-file compilation with the suite compiler.

// Source: lib/openzeppelin-contracts-upgradeable-v4.9.0/contracts/utils/AddressUpgradeable.sol
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// Source: lib/openzeppelin-contracts-upgradeable-v4.9.0/contracts/proxy/utils/Initializable.sol
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)




/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// Source: lib/openzeppelin-contracts-upgradeable-v4.9.0/contracts/utils/ContextUpgradeable.sol
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)




/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// Source: lib/openzeppelin-contracts-upgradeable-v4.9.0/contracts/access/OwnableUpgradeable.sol
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)






/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// Source: lib/openzeppelin-contracts-upgradeable-v4.9.0/contracts/security/ReentrancyGuardUpgradeable.sol
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)




/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// Source: lib/openzeppelin-contracts-v4.9.0/contracts/token/ERC20/IERC20.sol
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// Source: lib/openzeppelin-contracts-v4.9.0/contracts/token/ERC20/extensions/IERC20Permit.sol
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// Source: lib/openzeppelin-contracts-v4.9.0/contracts/utils/Address.sol
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// Source: lib/openzeppelin-contracts-v4.9.0/contracts/token/ERC20/utils/SafeERC20.sol
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)








/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// Source: lib/openzeppelin-contracts-upgradeable-v4.9.0/contracts/utils/StorageSlotUpgradeable.sol
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// Source: lib/openzeppelin-contracts-upgradeable-v4.9.0/contracts/utils/ShortStringsUpgradeable.sol
// OpenZeppelin Contracts (last updated v4.9.0) (utils/ShortStrings.sol)




// | string  | 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA   |
// | length  | 0x                                                              BB |
type ShortString is bytes32;

/**
 * @dev This library provides functions to convert short memory strings
 * into a `ShortString` type that can be used as an immutable variable.
 *
 * Strings of arbitrary length can be optimized using this library if
 * they are short enough (up to 31 bytes) by packing them with their
 * length (1 byte) in a single EVM word (32 bytes). Additionally, a
 * fallback mechanism can be used for every other case.
 *
 * Usage example:
 *
 * ```solidity
 * contract Named {
 *     using ShortStrings for *;
 *
 *     ShortString private immutable _name;
 *     string private _nameFallback;
 *
 *     constructor(string memory contractName) {
 *         _name = contractName.toShortStringWithFallback(_nameFallback);
 *     }
 *
 *     function name() external view returns (string memory) {
 *         return _name.toStringWithFallback(_nameFallback);
 *     }
 * }
 * ```
 */
library ShortStringsUpgradeable {
    // Used as an identifier for strings longer than 31 bytes.
    bytes32 private constant _FALLBACK_SENTINEL = 0x00000000000000000000000000000000000000000000000000000000000000FF;

    error StringTooLong(string str);
    error InvalidShortString();

    /**
     * @dev Encode a string of at most 31 chars into a `ShortString`.
     *
     * This will trigger a `StringTooLong` error is the input string is too long.
     */
    function toShortString(string memory str) internal pure returns (ShortString) {
        bytes memory bstr = bytes(str);
        if (bstr.length > 31) {
            revert StringTooLong(str);
        }
        return ShortString.wrap(bytes32(uint256(bytes32(bstr)) | bstr.length));
    }

    /**
     * @dev Decode a `ShortString` back to a "normal" string.
     */
    function toString(ShortString sstr) internal pure returns (string memory) {
        uint256 len = byteLength(sstr);
        // using `new string(len)` would work locally but is not memory safe.
        string memory str = new string(32);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(str, len)
            mstore(add(str, 0x20), sstr)
        }
        return str;
    }

    /**
     * @dev Return the length of a `ShortString`.
     */
    function byteLength(ShortString sstr) internal pure returns (uint256) {
        uint256 result = uint256(ShortString.unwrap(sstr)) & 0xFF;
        if (result > 31) {
            revert InvalidShortString();
        }
        return result;
    }

    /**
     * @dev Encode a string into a `ShortString`, or write it to storage if it is too long.
     */
    function toShortStringWithFallback(string memory value, string storage store) internal returns (ShortString) {
        if (bytes(value).length < 32) {
            return toShortString(value);
        } else {
            StorageSlotUpgradeable.getStringSlot(store).value = value;
            return ShortString.wrap(_FALLBACK_SENTINEL);
        }
    }

    /**
     * @dev Decode a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
     */
    function toStringWithFallback(ShortString value, string storage store) internal pure returns (string memory) {
        if (ShortString.unwrap(value) != _FALLBACK_SENTINEL) {
            return toString(value);
        } else {
            return store;
        }
    }

    /**
     * @dev Return the length of a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
     *
     * WARNING: This will return the "byte length" of the string. This may not reflect the actual length in terms of
     * actual characters as the UTF-8 encoding of a single character can span over multiple bytes.
     */
    function byteLengthWithFallback(ShortString value, string storage store) internal view returns (uint256) {
        if (ShortString.unwrap(value) != _FALLBACK_SENTINEL) {
            return byteLength(value);
        } else {
            return bytes(store).length;
        }
    }
}

// Source: lib/openzeppelin-contracts-upgradeable-v4.9.0/contracts/utils/math/MathUpgradeable.sol
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// Source: lib/openzeppelin-contracts-upgradeable-v4.9.0/contracts/utils/math/SignedMathUpgradeable.sol
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMathUpgradeable {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// Source: lib/openzeppelin-contracts-upgradeable-v4.9.0/contracts/utils/StringsUpgradeable.sol
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)






/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMathUpgradeable.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// Source: lib/openzeppelin-contracts-upgradeable-v4.9.0/contracts/utils/cryptography/ECDSAUpgradeable.sol
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)




/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// Source: lib/openzeppelin-contracts-upgradeable-v4.9.0/contracts/interfaces/IERC1271Upgradeable.sol
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271Upgradeable {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// Source: lib/openzeppelin-contracts-upgradeable-v4.9.0/contracts/utils/cryptography/SignatureCheckerUpgradeable.sol
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/SignatureChecker.sol)






/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureCheckerUpgradeable {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(address signer, bytes32 hash, bytes memory signature) internal view returns (bool) {
        (address recovered, ECDSAUpgradeable.RecoverError error) = ECDSAUpgradeable.tryRecover(hash, signature);
        return
            (error == ECDSAUpgradeable.RecoverError.NoError && recovered == signer) ||
            isValidERC1271SignatureNow(signer, hash, signature);
    }

    /**
     * @dev Checks if a signature is valid for a given signer and data hash. The signature is validated
     * against the signer smart contract using ERC1271.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidERC1271SignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271Upgradeable.isValidSignature.selector, hash, signature)
        );
        return (success &&
            result.length >= 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271Upgradeable.isValidSignature.selector));
    }
}

// Source: src/contracts/interfaces/ISignatureUtilsMixin.sol
interface ISignatureUtilsMixinErrors {
    /// @notice Thrown when a signature is invalid.
    error InvalidSignature();
    /// @notice Thrown when a signature has expired.
    error SignatureExpired();
}

interface ISignatureUtilsMixinTypes {
    /// @notice Struct that bundles together a signature and an expiration time for the signature.
    /// @dev Used primarily for stack management.
    struct SignatureWithExpiry {
        // the signature itself, formatted as a single bytes object
        bytes signature;
        // the expiration timestamp (UTC) of the signature
        uint256 expiry;
    }

    /// @notice Struct that bundles together a signature, a salt for uniqueness, and an expiration time for the signature.
    /// @dev Used primarily for stack management.
    struct SignatureWithSaltAndExpiry {
        // the signature itself, formatted as a single bytes object
        bytes signature;
        // the salt used to generate the signature
        bytes32 salt;
        // the expiration timestamp (UTC) of the signature
        uint256 expiry;
    }
}

/// @title The interface for common signature utilities.
/// @author Layr Labs, Inc.
/// @notice Terms of Service: https://docs.eigenlayer.xyz/overview/terms-of-service
interface ISignatureUtilsMixin is ISignatureUtilsMixinErrors, ISignatureUtilsMixinTypes {
    /// @notice Computes the EIP-712 domain separator used for signature validation.
    /// @dev The domain separator is computed according to EIP-712 specification, using:
    ///      - The hardcoded name "EigenLayer"
    ///      - The contract's version string
    ///      - The current chain ID
    ///      - This contract's address
    /// @return The 32-byte domain separator hash used in EIP-712 structured data signing.
    /// @dev See https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator.
    function domainSeparator() external view returns (bytes32);
}

// Source: src/contracts/interfaces/ISemVerMixin.sol
/// @title ISemVerMixin
/// @notice A mixin interface that provides semantic versioning functionality.
/// @dev Follows SemVer 2.0.0 specification (https://semver.org/)
interface ISemVerMixin {
    /// @notice Returns the semantic version string of the contract.
    /// @return The version string in SemVer format (e.g., "1.1.1")
    function version() external view returns (string memory);
}

// Source: src/contracts/mixins/SemVerMixin.sol
/// @title SemVerMixin
/// @notice A mixin contract that provides semantic versioning functionality.
/// @dev Follows SemVer 2.0.0 specification (https://semver.org/).
abstract contract SemVerMixin is ISemVerMixin {
    using ShortStringsUpgradeable for *;

    /// @notice The semantic version string for this contract, stored as a ShortString for gas efficiency.
    /// @dev Follows SemVer 2.0.0 specification (https://semver.org/).
    ShortString internal immutable _VERSION;

    /// @notice Initializes the contract with a semantic version string.
    /// @param _version The SemVer-formatted version string (e.g., "1.2.3")
    /// @dev Version should follow SemVer 2.0.0 format: MAJOR.MINOR.PATCH
    constructor(
        string memory _version
    ) {
        _VERSION = _version.toShortString();
    }

    /// @inheritdoc ISemVerMixin
    function version() public view virtual returns (string memory) {
        return _VERSION.toString();
    }

    /// @notice Returns the major version of the contract.
    /// @dev Supports single digit major versions (e.g., "1" for version "1.2.3")
    /// @return The major version string (e.g., "1" for version "1.2.3")
    function _majorVersion() internal view returns (string memory) {
        bytes memory v = bytes(_VERSION.toString());
        return string(abi.encodePacked(v[0]));
    }
}

// Source: src/contracts/mixins/SignatureUtilsMixin.sol
/// @dev The EIP-712 domain type hash used for computing the domain separator
///      See https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator
bytes32 constant EIP712_DOMAIN_TYPEHASH =
    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

/// @title SignatureUtilsMixin
/// @notice A mixin contract that provides utilities for validating signatures according to EIP-712 and EIP-1271 standards.
/// @dev The domain name is hardcoded to "EigenLayer". This contract implements signature validation functionality that can be
///      inherited by other contracts. The domain separator uses the major version (e.g., "v1") to maintain EIP-712
///      signature compatibility across minor and patch version updates.
abstract contract SignatureUtilsMixin is ISignatureUtilsMixin, SemVerMixin {
    using SignatureCheckerUpgradeable for address;

    /// @notice Initializes the contract with a semantic version string.
    /// @param _version The SemVer-formatted version string (e.g., "1.1.1") to use for this contract's domain separator.
    /// @dev Version should follow SemVer 2.0.0 format with 'v' prefix: vMAJOR.MINOR.PATCH.
    ///      Only the major version component is used in the domain separator to maintain signature compatibility
    ///      across minor and patch version updates.
    constructor(
        string memory _version
    ) SemVerMixin(_version) {}

    /// EXTERNAL FUNCTIONS ///

    /// @inheritdoc ISignatureUtilsMixin
    function domainSeparator() public view virtual returns (bytes32) {
        // forgefmt: disable-next-item
        return 
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH, 
                    keccak256(bytes("EigenLayer")),
                    keccak256(bytes(_majorVersion())),
                    block.chainid, 
                    address(this)
                )
            );
    }

    /// INTERNAL HELPERS ///

    /// @notice Creates a digest that can be signed using EIP-712.
    /// @dev Prepends the EIP-712 prefix ("\x19\x01") and domain separator to the input hash.
    ///      This follows the EIP-712 specification for creating structured data hashes.
    ///      See https://eips.ethereum.org/EIPS/eip-712#specification.
    /// @param hash The hash of the typed data to be signed.
    /// @return The complete digest that should be signed according to EIP-712.
    function _calculateSignableDigest(
        bytes32 hash
    ) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator(), hash));
    }

    /// @notice Validates a signature against a signer and digest, with an expiry timestamp.
    /// @dev Reverts if the signature is invalid or expired. Uses EIP-1271 for smart contract signers.
    ///      For EOA signers, validates ECDSA signatures directly.
    ///      For contract signers, calls isValidSignature according to EIP-1271.
    ///      See https://eips.ethereum.org/EIPS/eip-1271#specification.
    /// @param signer The address that should have signed the digest.
    /// @param signableDigest The digest that was signed, created via _calculateSignableDigest.
    /// @param signature The signature bytes to validate.
    /// @param expiry The timestamp after which the signature is no longer valid.
    function _checkIsValidSignatureNow(
        address signer,
        bytes32 signableDigest,
        bytes memory signature,
        uint256 expiry
    ) internal view {
        // First, check if the signature has expired by comparing the expiry timestamp
        // against the current block timestamp.
        require(expiry >= block.timestamp, SignatureExpired());

        // Next, verify that the signature is valid for the given signer and digest.
        // For EOA signers, this performs standard ECDSA signature verification.
        // For contract signers, this calls the EIP-1271 isValidSignature method.
        require(signer.isValidSignatureNow(signableDigest, signature), InvalidSignature());
    }
}

// Source: lib/openzeppelin-contracts-v4.9.0/contracts/proxy/beacon/IBeacon.sol
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// Source: src/contracts/interfaces/IETHPOSDeposit.sol
// ┏━━━┓━┏┓━┏┓━━┏━━━┓━━┏━━━┓━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━┏┓━━━━━┏━━━┓━━━━━━━━━┏┓━━━━━━━━━━━━━━┏┓━
// ┃┏━━┛┏┛┗┓┃┃━━┃┏━┓┃━━┃┏━┓┃━━━━┗┓┏┓┃━━━━━━━━━━━━━━━━━━┏┛┗┓━━━━┃┏━┓┃━━━━━━━━┏┛┗┓━━━━━━━━━━━━┏┛┗┓
// ┃┗━━┓┗┓┏┛┃┗━┓┗┛┏┛┃━━┃┃━┃┃━━━━━┃┃┃┃┏━━┓┏━━┓┏━━┓┏━━┓┏┓┗┓┏┛━━━━┃┃━┗┛┏━━┓┏━┓━┗┓┏┛┏━┓┏━━┓━┏━━┓┗┓┏┛
// ┃┏━━┛━┃┃━┃┏┓┃┏━┛┏┛━━┃┃━┃┃━━━━━┃┃┃┃┃┏┓┃┃┏┓┃┃┏┓┃┃━━┫┣┫━┃┃━━━━━┃┃━┏┓┃┏┓┃┃┏┓┓━┃┃━┃┏┛┗━┓┃━┃┏━┛━┃┃━
// ┃┗━━┓━┃┗┓┃┃┃┃┃┃┗━┓┏┓┃┗━┛┃━━━━┏┛┗┛┃┃┃━┫┃┗┛┃┃┗┛┃┣━━┃┃┃━┃┗┓━━━━┃┗━┛┃┃┗┛┃┃┃┃┃━┃┗┓┃┃━┃┗┛┗┓┃┗━┓━┃┗┓
// ┗━━━┛━┗━┛┗┛┗┛┗━━━┛┗┛┗━━━┛━━━━┗━━━┛┗━━┛┃┏━┛┗━━┛┗━━┛┗┛━┗━┛━━━━┗━━━┛┗━━┛┗┛┗┛━┗━┛┗┛━┗━━━┛┗━━┛━┗━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┃┃━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┗┛━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// This interface is designed to be compatible with the Vyper version.
/// @notice This is the Ethereum 2.0 deposit contract interface.
/// For more information see the Phase 0 specification under https://github.com/ethereum/eth2.0-specs
interface IETHPOSDeposit {
    /// @notice A processed deposit event.
    event DepositEvent(bytes pubkey, bytes withdrawal_credentials, bytes amount, bytes signature, bytes index);

    /// @notice Submit a Phase 0 DepositData object.
    /// @param pubkey A BLS12-381 public key.
    /// @param withdrawal_credentials Commitment to a public key for withdrawals.
    /// @param signature A BLS12-381 signature.
    /// @param deposit_data_root The SHA-256 hash of the SSZ-encoded DepositData object.
    /// Used as a protection against malformed input.
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable;

    /// @notice Query the current deposit root hash.
    /// @return The deposit root hash.
    function get_deposit_root() external view returns (bytes32);

    /// @notice Query the current deposit count.
    /// @return The deposit count encoded as a little endian 64-bit number.
    function get_deposit_count() external view returns (bytes memory);
}

// Source: lib/openzeppelin-contracts-v4.9.0/contracts/utils/math/Math.sol
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// Source: lib/openzeppelin-contracts-upgradeable-v4.9.0/contracts/utils/math/SafeCastUpgradeable.sol
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// Source: src/contracts/libraries/SlashingLib.sol
/// @dev All scaling factors have `1e18` as an initial/default value. This value is represented
/// by the constant `WAD`, which is used to preserve precision with uint256 math.
///
/// When applying scaling factors, they are typically multiplied/divided by `WAD`, allowing this
/// constant to act as a "1" in mathematical formulae.
uint64 constant WAD = 1e18;

/*
 * There are 2 types of shares:
 *      1. deposit shares
 *          - These can be converted to an amount of tokens given a strategy
 *              - by calling `sharesToUnderlying` on the strategy address (they're already tokens
 *              in the case of EigenPods)
 *          - These live in the storage of the EigenPodManager and individual StrategyManager strategies
 *      2. withdrawable shares
 *          - For a staker, this is the amount of shares that they can withdraw
 *          - For an operator, the shares delegated to them are equal to the sum of their stakers'
 *            withdrawable shares
 *
 * Along with a slashing factor, the DepositScalingFactor is used to convert between the two share types.
 */
struct DepositScalingFactor {
    uint256 _scalingFactor;
}

using SlashingLib for DepositScalingFactor global;

library SlashingLib {
    using Math for uint256;
    using SlashingLib for uint256;
    using SafeCastUpgradeable for uint256;

    /// @dev Thrown if an updated deposit scaling factor is 0 to avoid underflow.
    error InvalidDepositScalingFactor();

    // WAD MATH

    function mulWad(
        uint256 x,
        uint256 y
    ) internal pure returns (uint256) {
        return x.mulDiv(y, WAD);
    }

    function divWad(
        uint256 x,
        uint256 y
    ) internal pure returns (uint256) {
        return x.mulDiv(WAD, y);
    }

    /// @notice Used explicitly for calculating slashed magnitude, we want to ensure even in the
    /// situation where an operator is slashed several times and precision has been lost over time,
    /// an incoming slashing request isn't rounded down to 0 and an operator is able to avoid slashing penalties.
    function mulWadRoundUp(
        uint256 x,
        uint256 y
    ) internal pure returns (uint256) {
        return x.mulDiv(y, WAD, Math.Rounding.Up);
    }

    // GETTERS

    function scalingFactor(
        DepositScalingFactor memory dsf
    ) internal pure returns (uint256) {
        return dsf._scalingFactor == 0 ? WAD : dsf._scalingFactor;
    }

    function scaleForQueueWithdrawal(
        DepositScalingFactor memory dsf,
        uint256 depositSharesToWithdraw
    ) internal pure returns (uint256) {
        return depositSharesToWithdraw.mulWad(dsf.scalingFactor());
    }

    function scaleForCompleteWithdrawal(
        uint256 scaledShares,
        uint256 slashingFactor
    ) internal pure returns (uint256) {
        return scaledShares.mulWad(slashingFactor);
    }

    function update(
        DepositScalingFactor storage dsf,
        uint256 prevDepositShares,
        uint256 addedShares,
        uint256 slashingFactor
    ) internal {
        if (prevDepositShares == 0) {
            // If this is the staker's first deposit or they are delegating to an operator,
            // the slashing factor is inverted and applied to the existing DSF. This has the
            // effect of "forgiving" prior slashing for any subsequent deposits.
            dsf._scalingFactor = dsf.scalingFactor().divWad(slashingFactor);
            return;
        }

        /// Base Equations:
        /// (1) newShares = currentShares + addedShares
        /// (2) newDepositShares = prevDepositShares + addedShares
        /// (3) newShares = newDepositShares * newDepositScalingFactor * slashingFactor
        ///
        /// Plugging (1) into (3):
        /// (4) newDepositShares * newDepositScalingFactor * slashingFactor = currentShares + addedShares
        ///
        /// Solving for newDepositScalingFactor
        /// (5) newDepositScalingFactor = (currentShares + addedShares) / (newDepositShares * slashingFactor)
        ///
        /// Plugging in (2) into (5):
        /// (7) newDepositScalingFactor = (currentShares + addedShares) / ((prevDepositShares + addedShares) * slashingFactor)
        /// Note that magnitudes must be divided by WAD for precision. Thus,
        ///
        /// (8) newDepositScalingFactor = WAD * (currentShares + addedShares) / ((prevDepositShares + addedShares) * slashingFactor / WAD)
        /// (9) newDepositScalingFactor = (currentShares + addedShares) * WAD / (prevDepositShares + addedShares) * WAD / slashingFactor

        // Step 1: Calculate Numerator
        uint256 currentShares = dsf.calcWithdrawable(prevDepositShares, slashingFactor);

        // Step 2: Compute currentShares + addedShares
        uint256 newShares = currentShares + addedShares;

        // Step 3: Calculate newDepositScalingFactor
        /// forgefmt: disable-next-item
        uint256 newDepositScalingFactor = newShares
            .divWad(prevDepositShares + addedShares)
            .divWad(slashingFactor);

        dsf._scalingFactor = newDepositScalingFactor;

        // Avoid potential underflow.
        require(newDepositScalingFactor != 0, InvalidDepositScalingFactor());
    }

    /// @dev Reset the staker's DSF for a strategy by setting it to 0. This is the same
    /// as setting it to WAD (see the `scalingFactor` getter above).
    ///
    /// A DSF is reset when a staker reduces their deposit shares to 0, either by queueing
    /// a withdrawal, or undelegating from their operator. This ensures that subsequent
    /// delegations/deposits do not use a stale DSF (e.g. from a prior operator).
    function reset(
        DepositScalingFactor storage dsf
    ) internal {
        dsf._scalingFactor = 0;
    }

    // CONVERSION

    function calcWithdrawable(
        DepositScalingFactor memory dsf,
        uint256 depositShares,
        uint256 slashingFactor
    ) internal pure returns (uint256) {
        /// forgefmt: disable-next-item
        return depositShares
            .mulWad(dsf.scalingFactor())
            .mulWad(slashingFactor);
    }

    function calcDepositShares(
        DepositScalingFactor memory dsf,
        uint256 withdrawableShares,
        uint256 slashingFactor
    ) internal pure returns (uint256) {
        /// forgefmt: disable-next-item
        return withdrawableShares
            .divWad(dsf.scalingFactor())
            .divWad(slashingFactor);
    }

    /// @notice Calculates the amount of shares that should be slashed given the previous and new magnitudes.
    /// @param operatorShares The amount of shares to slash.
    /// @param prevMaxMagnitude The previous magnitude of the operator.
    /// @param newMaxMagnitude The new magnitude of the operator.
    /// @return The amount of shares that should be slashed.
    /// @dev This function will revert with a divide by zero error if the previous magnitude is 0.
    function calcSlashedAmount(
        uint256 operatorShares,
        uint256 prevMaxMagnitude,
        uint256 newMaxMagnitude
    ) internal pure returns (uint256) {
        // round up mulDiv so we don't overslash
        return operatorShares - operatorShares.mulDiv(newMaxMagnitude, prevMaxMagnitude, Math.Rounding.Up);
    }
}

// Source: src/contracts/interfaces/IStrategy.sol
interface IStrategyErrors {
    /// @dev Thrown when called by an account that is not strategy manager.
    error OnlyStrategyManager();
    /// @dev Thrown when new shares value is zero.
    error NewSharesZero();
    /// @dev Thrown when total shares exceeds max.
    error TotalSharesExceedsMax();
    /// @dev Thrown when amount shares is greater than total shares.
    error WithdrawalAmountExceedsTotalDeposits();
    /// @dev Thrown when attempting an action with a token that is not accepted.
    error OnlyUnderlyingToken();

    /// StrategyBaseWithTVLLimits

    /// @dev Thrown when `maxPerDeposit` exceeds max.
    error MaxPerDepositExceedsMax();
    /// @dev Thrown when balance exceeds max total deposits.
    error BalanceExceedsMaxTotalDeposits();
}

interface IStrategyEvents {
    /// @notice Used to emit an event for the exchange rate between 1 share and underlying token in a strategy contract
    /// @param rate is the exchange rate in wad 18 decimals
    /// @dev Tokens that do not have 18 decimals must have offchain services scale the exchange rate by the proper magnitude
    event ExchangeRateEmitted(uint256 rate);

    /// Used to emit the underlying token and its decimals on strategy creation
    /// @notice token
    /// @param token is the ERC20 token of the strategy
    /// @param decimals are the decimals of the ERC20 token in the strategy
    event StrategyTokenSet(IERC20 token, uint8 decimals);
}

/// @title Minimal interface for an `Strategy` contract.
/// @author Layr Labs, Inc.
/// @notice Terms of Service: https://docs.eigenlayer.xyz/overview/terms-of-service
/// @notice Custom `Strategy` implementations may expand extensively on this interface.
interface IStrategy is IStrategyErrors, IStrategyEvents {
    /// @notice Used to deposit tokens into this Strategy
    /// @param token is the ERC20 token being deposited
    /// @param amount is the amount of token being deposited
    /// @dev This function is only callable by the strategyManager contract. It is invoked inside of the strategyManager's
    /// `depositIntoStrategy` function, and individual share balances are recorded in the strategyManager as well.
    /// @return newShares is the number of new shares issued at the current exchange ratio.
    function deposit(
        IERC20 token,
        uint256 amount
    ) external returns (uint256);

    /// @notice Used to withdraw tokens from this Strategy, to the `recipient`'s address
    /// @param recipient is the address to receive the withdrawn funds
    /// @param token is the ERC20 token being transferred out
    /// @param amountShares is the amount of shares being withdrawn
    /// @dev This function is only callable by the strategyManager contract. It is invoked inside of the strategyManager's
    /// other functions, and individual share balances are recorded in the strategyManager as well.
    /// @return amountOut is the amount of tokens being transferred out.
    function withdraw(
        address recipient,
        IERC20 token,
        uint256 amountShares
    ) external returns (uint256);

    /// @notice Hook invoked by the StrategyManager before adding deposit shares for a staker.
    /// @dev Shares are added in the following scenarios:
    ///      - When a staker newly deposits into a strategy via StrategyManager.depositIntoStrategy
    ///      - When completing a withdrawal as shares via DelegationManager.completeQueuedWithdrawal
    /// @param staker The address receiving shares.
    /// @param shares The number of shares being added.
    function beforeAddShares(
        address staker,
        uint256 shares
    ) external;

    /// @notice Hook invoked by the StrategyManager before removing deposit shares for a staker.
    /// @dev Deposit shares are removed when a withdrawal is queued via DelegationManager.queueWithdrawals.
    /// @param staker The address losing shares.
    /// @param shares The number of shares being removed.
    function beforeRemoveShares(
        address staker,
        uint256 shares
    ) external;

    /// @notice Used to convert a number of shares to the equivalent amount of underlying tokens for this strategy.
    /// For a staker using this function and trying to calculate the amount of underlying tokens they have in total they
    /// should input into `amountShares` their withdrawable shares read from the `DelegationManager` contract.
    /// @notice In contrast to `sharesToUnderlyingView`, this function **may** make state modifications
    /// @param amountShares is the amount of shares to calculate its conversion into the underlying token
    /// @return The amount of underlying tokens corresponding to the input `amountShares`
    /// @dev Implementation for these functions in particular may vary significantly for different strategies
    function sharesToUnderlying(
        uint256 amountShares
    ) external returns (uint256);

    /// @notice Used to convert an amount of underlying tokens to the equivalent amount of shares in this strategy.
    /// @notice In contrast to `underlyingToSharesView`, this function **may** make state modifications
    /// @param amountUnderlying is the amount of `underlyingToken` to calculate its conversion into strategy shares
    /// @return The amount of shares corresponding to the input `amountUnderlying`.  This is used as deposit shares
    /// in the `StrategyManager` contract.
    /// @dev Implementation for these functions in particular may vary significantly for different strategies
    function underlyingToShares(
        uint256 amountUnderlying
    ) external returns (uint256);

    /// @notice convenience function for fetching the current underlying value of all of the `user`'s shares in
    /// this strategy. In contrast to `userUnderlyingView`, this function **may** make state modifications
    function userUnderlying(
        address user
    ) external returns (uint256);

    /// @notice convenience function for fetching the current total shares of `user` in this strategy, by
    /// querying the `strategyManager` contract
    function shares(
        address user
    ) external view returns (uint256);

    /// @notice Used to convert a number of shares to the equivalent amount of underlying tokens for this strategy.
    /// For a staker using this function and trying to calculate the amount of underlying tokens they have in total they
    /// should input into `amountShares` their withdrawable shares read from the `DelegationManager` contract.
    /// @notice In contrast to `sharesToUnderlying`, this function guarantees no state modifications
    /// @param amountShares is the amount of shares to calculate its conversion into the underlying token
    /// @return The amount of underlying tokens corresponding to the input `amountShares`
    /// @dev Implementation for these functions in particular may vary significantly for different strategies
    function sharesToUnderlyingView(
        uint256 amountShares
    ) external view returns (uint256);

    /// @notice Used to convert an amount of underlying tokens to the equivalent amount of shares in this strategy.
    /// @notice In contrast to `underlyingToShares`, this function guarantees no state modifications
    /// @param amountUnderlying is the amount of `underlyingToken` to calculate its conversion into strategy shares
    /// @return The amount of shares corresponding to the input `amountUnderlying`. This is used as deposit shares
    /// in the `StrategyManager` contract.
    /// @dev Implementation for these functions in particular may vary significantly for different strategies
    function underlyingToSharesView(
        uint256 amountUnderlying
    ) external view returns (uint256);

    /// @notice convenience function for fetching the current underlying value of all of the `user`'s shares in
    /// this strategy. In contrast to `userUnderlying`, this function guarantees no state modifications
    function userUnderlyingView(
        address user
    ) external view returns (uint256);

    /// @notice The underlying token for shares in this Strategy
    function underlyingToken() external view returns (IERC20);

    /// @notice The total number of extant shares in this Strategy
    function totalShares() external view returns (uint256);

    /// @notice Returns either a brief string explaining the strategy's goal & purpose, or a link to metadata that explains in more detail.
    function explanation() external view returns (string memory);
}

// Source: src/contracts/libraries/OperatorSetLib.sol
using OperatorSetLib for OperatorSet global;

/// @notice An operator set identified by the AVS address and an identifier
/// @param avs The address of the AVS this operator set belongs to
/// @param id The unique identifier for the operator set
struct OperatorSet {
    address avs;
    uint32 id;
}

library OperatorSetLib {
    function key(
        OperatorSet memory os
    ) internal pure returns (bytes32) {
        return bytes32(abi.encodePacked(os.avs, uint96(os.id)));
    }

    function decode(
        bytes32 _key
    ) internal pure returns (OperatorSet memory) {
        /// forgefmt: disable-next-item
        return OperatorSet({
            avs: address(uint160(uint256(_key) >> 96)),
            id: uint32(uint256(_key) & type(uint96).max)
        });
    }
}

// Source: src/contracts/interfaces/IShareManager.sol
/// @title Interface for a `IShareManager` contract.
/// @author Layr Labs, Inc.
/// @notice Terms of Service: https://docs.eigenlayer.xyz/overview/terms-of-service
/// @notice This contract is used by the DelegationManager as a unified interface to interact with the EigenPodManager and StrategyManager

interface IShareManager {
    /// @notice Used by the DelegationManager to remove a Staker's shares from a particular strategy when entering the withdrawal queue
    /// @dev strategy must be beaconChainETH when talking to the EigenPodManager
    /// @return updatedShares the staker's deposit shares after decrement
    function removeDepositShares(
        address staker,
        IStrategy strategy,
        uint256 depositSharesToRemove
    ) external returns (uint256);

    /// @notice Used by the DelegationManager to award a Staker some shares that have passed through the withdrawal queue
    /// @dev strategy must be beaconChainETH when talking to the EigenPodManager
    /// @return existingDepositShares the shares the staker had before any were added
    /// @return addedShares the new shares added to the staker's balance
    function addShares(
        address staker,
        IStrategy strategy,
        uint256 shares
    ) external returns (uint256, uint256);

    /// @notice Used by the DelegationManager to convert deposit shares to tokens and send them to a staker
    /// @dev strategy must be beaconChainETH when talking to the EigenPodManager
    /// @dev token is not validated when talking to the EigenPodManager
    function withdrawSharesAsTokens(
        address staker,
        IStrategy strategy,
        IERC20 token,
        uint256 shares
    ) external;

    /// @notice Returns the current shares of `user` in `strategy`
    /// @dev strategy must be beaconChainETH when talking to the EigenPodManager
    /// @dev returns 0 if the user has negative shares
    function stakerDepositShares(
        address user,
        IStrategy strategy
    ) external view returns (uint256 depositShares);

    /// @notice Increase the amount of burnable/redistributable shares for a given Strategy. This is called by the DelegationManager
    /// when an operator is slashed in EigenLayer.
    /// @param operatorSet The operator set to burn shares in.
    /// @param slashId The slash id to burn shares in.
    /// @param strategy The strategy to burn shares in.
    /// @param addedSharesToBurn The amount of added shares to burn.
    /// @dev This function is only called by the DelegationManager when an operator is slashed.
    function increaseBurnOrRedistributableShares(
        OperatorSet calldata operatorSet,
        uint256 slashId,
        IStrategy strategy,
        uint256 addedSharesToBurn
    ) external;
}

// Source: src/contracts/interfaces/IPauserRegistry.sol
/// @title Interface for the `PauserRegistry` contract.
/// @author Layr Labs, Inc.
/// @notice Terms of Service: https://docs.eigenlayer.xyz/overview/terms-of-service
interface IPauserRegistry {
    error OnlyUnpauser();
    error InputAddressZero();

    event PauserStatusChanged(address pauser, bool canPause);

    event UnpauserChanged(address previousUnpauser, address newUnpauser);

    /// @notice Mapping of addresses to whether they hold the pauser role.
    function isPauser(
        address pauser
    ) external view returns (bool);

    /// @notice Unique address that holds the unpauser role. Capable of changing *both* the pauser and unpauser addresses.
    function unpauser() external view returns (address);
}

// Source: src/contracts/interfaces/IDelegationManager.sol
interface IDelegationManagerErrors {
    /// @dev Thrown when caller is neither the StrategyManager or EigenPodManager contract.
    error OnlyStrategyManagerOrEigenPodManager();
    /// @dev Thrown when msg.sender is not the EigenPodManager
    error OnlyEigenPodManager();
    /// @dev Throw when msg.sender is not the AllocationManager
    error OnlyAllocationManager();

    /// Delegation Status

    /// @dev Thrown when an operator attempts to undelegate.
    error OperatorsCannotUndelegate();
    /// @dev Thrown when an account is actively delegated.
    error ActivelyDelegated();
    /// @dev Thrown when an account is not actively delegated.
    error NotActivelyDelegated();
    /// @dev Thrown when `operator` is not a registered operator.
    error OperatorNotRegistered();

    /// Invalid Inputs

    /// @dev Thrown when attempting to execute an action that was not queued.
    error WithdrawalNotQueued();
    /// @dev Thrown when caller cannot undelegate on behalf of a staker.
    error CallerCannotUndelegate();
    /// @dev Thrown when two array parameters have mismatching lengths.
    error InputArrayLengthMismatch();
    /// @dev Thrown when input arrays length is zero.
    error InputArrayLengthZero();

    /// Slashing

    /// @dev Thrown when an operator has been fully slashed(maxMagnitude is 0) for a strategy.
    /// or if the staker has had been natively slashed to the point of their beaconChainScalingFactor equalling 0.
    error FullySlashed();

    /// Signatures

    /// @dev Thrown when attempting to spend a spent eip-712 salt.
    error SaltSpent();

    /// Withdrawal Processing

    /// @dev Thrown when attempting to withdraw before delay has elapsed.
    error WithdrawalDelayNotElapsed();
    /// @dev Thrown when withdrawer is not the current caller.
    error WithdrawerNotCaller();
}

interface IDelegationManagerTypes {
    // @notice Struct used for storing information about a single operator who has registered with EigenLayer
    struct OperatorDetails {
        /// @notice DEPRECATED -- this field is no longer used, payments are handled in RewardsCoordinator.sol
        address __deprecated_earningsReceiver;
        /// @notice Address to verify signatures when a staker wishes to delegate to the operator, as well as controlling "forced undelegations".
        /// @dev Signature verification follows these rules:
        /// 1) If this address is left as address(0), then any staker will be free to delegate to the operator, i.e. no signature verification will be performed.
        /// 2) If this address is an EOA (i.e. it has no code), then we follow standard ECDSA signature verification for delegations to the operator.
        /// 3) If this address is a contract (i.e. it has code) then we forward a call to the contract and verify that it returns the correct EIP-1271 "magic value".
        address delegationApprover;
        /// @notice DEPRECATED -- this field is no longer used. An analogous field is the `allocationDelay` stored in the AllocationManager
        uint32 __deprecated_stakerOptOutWindowBlocks;
    }

    /// @notice Abstract struct used in calculating an EIP712 signature for an operator's delegationApprover to approve that a specific staker delegate to the operator.
    /// @dev Used in computing the `DELEGATION_APPROVAL_TYPEHASH` and as a reference in the computation of the approverDigestHash in the `_delegate` function.
    struct DelegationApproval {
        // the staker who is delegating
        address staker;
        // the operator being delegated to
        address operator;
        // the operator's provided salt
        bytes32 salt;
        // the expiration timestamp (UTC) of the signature
        uint256 expiry;
    }

    /// @dev A struct representing an existing queued withdrawal. After the withdrawal delay has elapsed, this withdrawal can be completed via `completeQueuedWithdrawal`.
    /// A `Withdrawal` is created by the `DelegationManager` when `queueWithdrawals` is called. The `withdrawalRoots` hashes returned by `queueWithdrawals` can be used
    /// to fetch the corresponding `Withdrawal` from storage (via `getQueuedWithdrawal`).
    ///
    /// @param staker The address that queued the withdrawal
    /// @param delegatedTo The address that the staker was delegated to at the time the withdrawal was queued. Used to determine if additional slashing occurred before
    /// this withdrawal became completable.
    /// @param withdrawer The address that will call the contract to complete the withdrawal. Note that this will always equal `staker`; alternate withdrawers are not
    /// supported at this time.
    /// @param nonce The staker's `cumulativeWithdrawalsQueued` at time of queuing. Used to ensure withdrawals have unique hashes.
    /// @param startBlock The block number when the withdrawal was queued.
    /// @param strategies The strategies requested for withdrawal when the withdrawal was queued
    /// @param scaledShares The staker's deposit shares requested for withdrawal, scaled by the staker's `depositScalingFactor`. Upon completion, these will be
    /// scaled by the appropriate slashing factor as of the withdrawal's completable block. The result is what is actually withdrawable.
    struct Withdrawal {
        address staker;
        address delegatedTo;
        address withdrawer;
        uint256 nonce;
        uint32 startBlock;
        IStrategy[] strategies;
        uint256[] scaledShares;
    }

    /// @param strategies The strategies to withdraw from
    /// @param depositShares For each strategy, the number of deposit shares to withdraw. Deposit shares can
    /// be queried via `getDepositedShares`.
    /// NOTE: The number of shares ultimately received when a withdrawal is completed may be lower depositShares
    /// if the staker or their delegated operator has experienced slashing.
    /// @param __deprecated_withdrawer This field is ignored. The only party that may complete a withdrawal
    /// is the staker that originally queued it. Alternate withdrawers are not supported.
    struct QueuedWithdrawalParams {
        IStrategy[] strategies;
        uint256[] depositShares;
        address __deprecated_withdrawer;
    }
}

interface IDelegationManagerEvents is IDelegationManagerTypes {
    // @notice Emitted when a new operator registers in EigenLayer and provides their delegation approver.
    event OperatorRegistered(address indexed operator, address delegationApprover);

    /// @notice Emitted when an operator updates their delegation approver
    event DelegationApproverUpdated(address indexed operator, address newDelegationApprover);

    /// @notice Emitted when @param operator indicates that they are updating their MetadataURI string
    /// @dev Note that these strings are *never stored in storage* and are instead purely emitted in events for off-chain indexing
    event OperatorMetadataURIUpdated(address indexed operator, string metadataURI);

    /// @notice Emitted whenever an operator's shares are increased for a given strategy. Note that shares is the delta in the operator's shares.
    event OperatorSharesIncreased(address indexed operator, address staker, IStrategy strategy, uint256 shares);

    /// @notice Emitted whenever an operator's shares are decreased for a given strategy. Note that shares is the delta in the operator's shares.
    event OperatorSharesDecreased(address indexed operator, address staker, IStrategy strategy, uint256 shares);

    /// @notice Emitted when @param staker delegates to @param operator.
    event StakerDelegated(address indexed staker, address indexed operator);

    /// @notice Emitted when @param staker undelegates from @param operator.
    event StakerUndelegated(address indexed staker, address indexed operator);

    /// @notice Emitted when @param staker is undelegated via a call not originating from the staker themself
    event StakerForceUndelegated(address indexed staker, address indexed operator);

    /// @notice Emitted when a staker's depositScalingFactor is updated
    event DepositScalingFactorUpdated(address staker, IStrategy strategy, uint256 newDepositScalingFactor);

    /// @notice Emitted when a new withdrawal is queued.
    /// @param withdrawalRoot Is the hash of the `withdrawal`.
    /// @param withdrawal Is the withdrawal itself.
    /// @param sharesToWithdraw Is an array of the expected shares that were queued for withdrawal corresponding to the strategies in the `withdrawal`.
    event SlashingWithdrawalQueued(bytes32 withdrawalRoot, Withdrawal withdrawal, uint256[] sharesToWithdraw);

    /// @notice Emitted when a queued withdrawal is completed
    event SlashingWithdrawalCompleted(bytes32 withdrawalRoot);

    /// @notice Emitted whenever an operator's shares are slashed for a given strategy
    event OperatorSharesSlashed(address indexed operator, IStrategy strategy, uint256 totalSlashedShares);
}

/// @title DelegationManager
/// @author Layr Labs, Inc.
/// @notice Terms of Service: https://docs.eigenlayer.xyz/overview/terms-of-service
/// @notice  This is the contract for delegation in EigenLayer. The main functionalities of this contract are
/// - enabling anyone to register as an operator in EigenLayer
/// - allowing operators to specify parameters related to stakers who delegate to them
/// - enabling any staker to delegate its stake to the operator of its choice (a given staker can only delegate to a single operator at a time)
/// - enabling a staker to undelegate its assets from the operator it is delegated to (performed as part of the withdrawal process, initiated through the StrategyManager)
interface IDelegationManager is ISignatureUtilsMixin, IDelegationManagerErrors, IDelegationManagerEvents {
    /// @dev Initializes the initial owner and paused status.
    function initialize(
        uint256 initialPausedStatus
    ) external;

    /// @notice Registers the caller as an operator in EigenLayer.
    /// @param initDelegationApprover is an address that, if set, must provide a signature when stakers delegate
    /// to an operator.
    /// @param allocationDelay The delay before allocations take effect.
    /// @param metadataURI is a URI for the operator's metadata, i.e. a link providing more details on the operator.
    ///
    /// @dev Once an operator is registered, they cannot 'deregister' as an operator, and they will forever be considered "delegated to themself".
    /// @dev This function will revert if the caller is already delegated to an operator.
    /// @dev Note that the `metadataURI` is *never stored * and is only emitted in the `OperatorMetadataURIUpdated` event
    function registerAsOperator(
        address initDelegationApprover,
        uint32 allocationDelay,
        string calldata metadataURI
    ) external;

    /// @notice Updates an operator's stored `delegationApprover`.
    /// @param operator is the operator to update the delegationApprover for
    /// @param newDelegationApprover is the new delegationApprover for the operator
    ///
    /// @dev The caller must have previously registered as an operator in EigenLayer.
    function modifyOperatorDetails(
        address operator,
        address newDelegationApprover
    ) external;

    /// @notice Called by an operator to emit an `OperatorMetadataURIUpdated` event indicating the information has updated.
    /// @param operator The operator to update metadata for
    /// @param metadataURI The URI for metadata associated with an operator
    /// @dev Note that the `metadataURI` is *never stored * and is only emitted in the `OperatorMetadataURIUpdated` event
    function updateOperatorMetadataURI(
        address operator,
        string calldata metadataURI
    ) external;

    /// @notice Caller delegates their stake to an operator.
    /// @param operator The account (`msg.sender`) is delegating its assets to for use in serving applications built on EigenLayer.
    /// @param approverSignatureAndExpiry (optional) Verifies the operator approves of this delegation
    /// @param approverSalt (optional) A unique single use value tied to an individual signature.
    /// @dev The signature/salt are used ONLY if the operator has configured a delegationApprover.
    /// If they have not, these params can be left empty.
    function delegateTo(
        address operator,
        SignatureWithExpiry memory approverSignatureAndExpiry,
        bytes32 approverSalt
    ) external;

    /// @notice Undelegates the staker from their operator and queues a withdrawal for all of their shares
    /// @param staker The account to be undelegated
    /// @return withdrawalRoots The roots of the newly queued withdrawals, if a withdrawal was queued. Returns
    /// an empty array if none was queued.
    ///
    /// @dev Reverts if the `staker` is also an operator, since operators are not allowed to undelegate from themselves.
    /// @dev Reverts if the caller is not the staker, nor the operator who the staker is delegated to, nor the operator's specified "delegationApprover"
    /// @dev Reverts if the `staker` is not delegated to an operator
    function undelegate(
        address staker
    ) external returns (bytes32[] memory withdrawalRoots);

    /// @notice Undelegates the staker from their current operator, and redelegates to `newOperator`
    /// Queues a withdrawal for all of the staker's withdrawable shares. These shares will only be
    /// delegated to `newOperator` AFTER the withdrawal is completed.
    /// @dev This method acts like a call to `undelegate`, then `delegateTo`
    /// @param newOperator the new operator that will be delegated all assets
    /// @dev NOTE: the following 2 params are ONLY checked if `newOperator` has a `delegationApprover`.
    /// If not, they can be left empty.
    /// @param newOperatorApproverSig A signature from the operator's `delegationApprover`
    /// @param approverSalt A unique single use value tied to the approver's signature
    function redelegate(
        address newOperator,
        SignatureWithExpiry memory newOperatorApproverSig,
        bytes32 approverSalt
    ) external returns (bytes32[] memory withdrawalRoots);

    /// @notice Allows a staker to queue a withdrawal of their deposit shares. The withdrawal can be
    /// completed after the MIN_WITHDRAWAL_DELAY_BLOCKS via either of the completeQueuedWithdrawal methods.
    ///
    /// While in the queue, these shares are removed from the staker's balance, as well as from their operator's
    /// delegated share balance (if applicable). Note that while in the queue, deposit shares are still subject
    /// to slashing. If any slashing has occurred, the shares received may be less than the queued deposit shares.
    ///
    /// @dev To view all the staker's strategies/deposit shares that can be queued for withdrawal, see `getDepositedShares`
    /// @dev To view the current conversion between a staker's deposit shares and withdrawable shares, see `getWithdrawableShares`
    function queueWithdrawals(
        QueuedWithdrawalParams[] calldata params
    ) external returns (bytes32[] memory);

    /// @notice Used to complete a queued withdrawal
    /// @param withdrawal The withdrawal to complete
    /// @param tokens Array in which the i-th entry specifies the `token` input to the 'withdraw' function of the i-th Strategy in the `withdrawal.strategies` array.
    /// @param tokens For each `withdrawal.strategies`, the underlying token of the strategy
    /// NOTE: if `receiveAsTokens` is false, the `tokens` array is unused and can be filled with default values. However, `tokens.length` MUST still be equal to `withdrawal.strategies.length`.
    /// NOTE: For the `beaconChainETHStrategy`, the corresponding `tokens` value is ignored (can be 0).
    /// @param receiveAsTokens If true, withdrawn shares will be converted to tokens and sent to the caller. If false, the caller receives shares that can be delegated to an operator.
    /// NOTE: if the caller receives shares and is currently delegated to an operator, the received shares are
    /// automatically delegated to the caller's current operator.
    function completeQueuedWithdrawal(
        Withdrawal calldata withdrawal,
        IERC20[] calldata tokens,
        bool receiveAsTokens
    ) external;

    /// @notice Used to complete multiple queued withdrawals
    /// @param withdrawals Array of Withdrawals to complete. See `completeQueuedWithdrawal` for the usage of a single Withdrawal.
    /// @param tokens Array of tokens for each Withdrawal. See `completeQueuedWithdrawal` for the usage of a single array.
    /// @param receiveAsTokens Whether or not to complete each withdrawal as tokens. See `completeQueuedWithdrawal` for the usage of a single boolean.
    /// @dev See `completeQueuedWithdrawal` for relevant dev tags
    function completeQueuedWithdrawals(
        Withdrawal[] calldata withdrawals,
        IERC20[][] calldata tokens,
        bool[] calldata receiveAsTokens
    ) external;

    /// @notice Called by a share manager when a staker's deposit share balance in a strategy increases.
    /// This method delegates any new shares to an operator (if applicable), and updates the staker's
    /// deposit scaling factor regardless.
    /// @param staker The address whose deposit shares have increased
    /// @param strategy The strategy in which shares have been deposited
    /// @param prevDepositShares The number of deposit shares the staker had in the strategy prior to the increase
    /// @param addedShares The number of deposit shares added by the staker
    ///
    /// @dev Note that if the either the staker's current operator has been slashed 100% for `strategy`, OR the
    /// staker has been slashed 100% on the beacon chain such that the calculated slashing factor is 0, this
    /// method WILL REVERT.
    function increaseDelegatedShares(
        address staker,
        IStrategy strategy,
        uint256 prevDepositShares,
        uint256 addedShares
    ) external;

    /// @notice If the staker is delegated, decreases its operator's shares in response to
    /// a decrease in balance in the beaconChainETHStrategy
    /// @param staker the staker whose operator's balance will be decreased
    /// @param curDepositShares the current deposit shares held by the staker
    /// @param beaconChainSlashingFactorDecrease the amount that the staker's beaconChainSlashingFactor has decreased by
    /// @dev Note: `beaconChainSlashingFactorDecrease` are assumed to ALWAYS be < 1 WAD.
    /// These invariants are maintained in the EigenPodManager.
    function decreaseDelegatedShares(
        address staker,
        uint256 curDepositShares,
        uint64 beaconChainSlashingFactorDecrease
    ) external;

    /// @notice Decreases the operator's shares in storage after a slash and increases the burnable shares by calling
    /// into either the StrategyManager or EigenPodManager (if the strategy is beaconChainETH).
    /// @param operator The operator to decrease shares for.
    /// @param operatorSet The operator set to decrease shares for.
    /// @param slashId The slash id to decrease shares for.
    /// @param strategy The strategy to decrease shares for.
    /// @param prevMaxMagnitude The previous maxMagnitude of the operator.
    /// @param newMaxMagnitude The new maxMagnitude of the operator.
    /// @dev Callable only by the AllocationManager.
    /// @dev Note: Assumes `prevMaxMagnitude <= newMaxMagnitude`. This invariant is maintained in
    /// the AllocationManager.
    /// @return totalDepositSharesToSlash The total deposit shares to burn or redistribute.
    function slashOperatorShares(
        address operator,
        OperatorSet calldata operatorSet,
        uint256 slashId,
        IStrategy strategy,
        uint64 prevMaxMagnitude,
        uint64 newMaxMagnitude
    ) external returns (uint256 totalDepositSharesToSlash);

    ///
    ///                         VIEW FUNCTIONS
    ///

    /// @notice returns the address of the operator that `staker` is delegated to.
    /// @notice Mapping: staker => operator whom the staker is currently delegated to.
    /// @dev Note that returning address(0) indicates that the staker is not actively delegated to any operator.
    function delegatedTo(
        address staker
    ) external view returns (address);

    /// @notice Mapping: delegationApprover => 32-byte salt => whether or not the salt has already been used by the delegationApprover.
    /// @dev Salts are used in the `delegateTo` function. Note that this function only processes the delegationApprover's
    /// signature + the provided salt if the operator being delegated to has specified a nonzero address as their `delegationApprover`.
    function delegationApproverSaltIsSpent(
        address _delegationApprover,
        bytes32 salt
    ) external view returns (bool);

    /// @notice Mapping: staker => cumulative number of queued withdrawals they have ever initiated.
    /// @dev This only increments (doesn't decrement), and is used to help ensure that otherwise identical withdrawals have unique hashes.
    function cumulativeWithdrawalsQueued(
        address staker
    ) external view returns (uint256);

    /// @notice Returns 'true' if `staker` *is* actively delegated, and 'false' otherwise.
    function isDelegated(
        address staker
    ) external view returns (bool);

    /// @notice Returns true is an operator has previously registered for delegation.
    function isOperator(
        address operator
    ) external view returns (bool);

    /// @notice Returns the delegationApprover account for an operator
    function delegationApprover(
        address operator
    ) external view returns (address);

    /// @notice Returns the shares that an operator has delegated to them in a set of strategies
    /// @param operator the operator to get shares for
    /// @param strategies the strategies to get shares for
    function getOperatorShares(
        address operator,
        IStrategy[] memory strategies
    ) external view returns (uint256[] memory);

    /// @notice Returns the shares that a set of operators have delegated to them in a set of strategies
    /// @param operators the operators to get shares for
    /// @param strategies the strategies to get shares for
    function getOperatorsShares(
        address[] memory operators,
        IStrategy[] memory strategies
    ) external view returns (uint256[][] memory);

    /// @notice Returns amount of withdrawable shares from an operator for a strategy that is still in the queue
    /// and therefore slashable.
    /// @param operator the operator to get shares for
    /// @param strategy the strategy to get shares for
    /// @return the amount of shares that are slashable in the withdrawal queue for an operator and a strategy
    /// @dev If multiple slashes occur to shares in the queue, the function properly accounts for the fewer
    ///      number of shares that are available to be slashed.
    function getSlashableSharesInQueue(
        address operator,
        IStrategy strategy
    ) external view returns (uint256);

    /// @notice Given a staker and a set of strategies, return the shares they can queue for withdrawal and the
    /// corresponding depositShares.
    /// This value depends on which operator the staker is delegated to.
    /// The shares amount returned is the actual amount of Strategy shares the staker would receive (subject
    /// to each strategy's underlying shares to token ratio).
    function getWithdrawableShares(
        address staker,
        IStrategy[] memory strategies
    ) external view returns (uint256[] memory withdrawableShares, uint256[] memory depositShares);

    /// @notice Returns the number of shares in storage for a staker and all their strategies
    function getDepositedShares(
        address staker
    ) external view returns (IStrategy[] memory, uint256[] memory);

    /// @notice Returns the scaling factor applied to a staker's deposits for a given strategy
    function depositScalingFactor(
        address staker,
        IStrategy strategy
    ) external view returns (uint256);

    /// @notice Returns the Withdrawal associated with a `withdrawalRoot`.
    /// @param withdrawalRoot The hash identifying the queued withdrawal.
    /// @return withdrawal The withdrawal details.
    function queuedWithdrawals(
        bytes32 withdrawalRoot
    ) external view returns (Withdrawal memory withdrawal);

    /// @notice Returns the Withdrawal and corresponding shares associated with a `withdrawalRoot`
    /// @param withdrawalRoot The hash identifying the queued withdrawal
    /// @return withdrawal The withdrawal details
    /// @return shares Array of shares corresponding to each strategy in the withdrawal
    /// @dev The shares are what a user would receive from completing a queued withdrawal, assuming all slashings are applied
    /// @dev Withdrawals queued before the slashing release cannot be queried with this method
    function getQueuedWithdrawal(
        bytes32 withdrawalRoot
    ) external view returns (Withdrawal memory withdrawal, uint256[] memory shares);

    /// @notice Returns all queued withdrawals and their corresponding shares for a staker.
    /// @param staker The address of the staker to query withdrawals for.
    /// @return withdrawals Array of Withdrawal structs containing details about each queued withdrawal.
    /// @return shares 2D array of shares, where each inner array corresponds to the strategies in the withdrawal.
    /// @dev The shares are what a user would receive from completing a queued withdrawal, assuming all slashings are applied.
    function getQueuedWithdrawals(
        address staker
    ) external view returns (Withdrawal[] memory withdrawals, uint256[][] memory shares);

    /// @notice Returns a list of queued withdrawal roots for the `staker`.
    /// NOTE that this only returns withdrawals queued AFTER the slashing release.
    function getQueuedWithdrawalRoots(
        address staker
    ) external view returns (bytes32[] memory);

    /// @notice Converts shares for a set of strategies to deposit shares, likely in order to input into `queueWithdrawals`.
    /// This function will revert from a division by 0 error if any of the staker's strategies have a slashing factor of 0.
    /// @param staker the staker to convert shares for
    /// @param strategies the strategies to convert shares for
    /// @param withdrawableShares the shares to convert
    /// @return the deposit shares
    /// @dev will be a few wei off due to rounding errors
    function convertToDepositShares(
        address staker,
        IStrategy[] memory strategies,
        uint256[] memory withdrawableShares
    ) external view returns (uint256[] memory);

    /// @notice Returns the keccak256 hash of `withdrawal`.
    function calculateWithdrawalRoot(
        Withdrawal memory withdrawal
    ) external pure returns (bytes32);

    /// @notice Calculates the digest hash to be signed by the operator's delegationApprove and used in the `delegateTo` function.
    /// @param staker The account delegating their stake
    /// @param operator The account receiving delegated stake
    /// @param _delegationApprover the operator's `delegationApprover` who will be signing the delegationHash (in general)
    /// @param approverSalt A unique and single use value associated with the approver signature.
    /// @param expiry Time after which the approver's signature becomes invalid
    function calculateDelegationApprovalDigestHash(
        address staker,
        address operator,
        address _delegationApprover,
        bytes32 approverSalt,
        uint256 expiry
    ) external view returns (bytes32);

    /// @notice return address of the beaconChainETHStrategy
    function beaconChainETHStrategy() external view returns (IStrategy);

    /// @notice Returns the minimum withdrawal delay in blocks to pass for withdrawals queued to be completable.
    /// Also applies to legacy withdrawals so any withdrawals not completed prior to the slashing upgrade will be subject
    /// to this longer delay.
    /// @dev Backwards-compatible interface to return the internal `MIN_WITHDRAWAL_DELAY_BLOCKS` value
    /// @dev Previous value in storage was deprecated. See `__deprecated_minWithdrawalDelayBlocks`
    function minWithdrawalDelayBlocks() external view returns (uint32);

    /// @notice The EIP-712 typehash for the DelegationApproval struct used by the contract
    function DELEGATION_APPROVAL_TYPEHASH() external view returns (bytes32);
}

// Source: src/contracts/interfaces/IStrategyManager.sol
interface IStrategyManagerErrors {
    /// @dev Thrown when total strategies deployed exceeds max.
    error MaxStrategiesExceeded();
    /// @dev Thrown when call attempted from address that's not delegation manager.
    error OnlyDelegationManager();
    /// @dev Thrown when call attempted from address that's not strategy whitelister.
    error OnlyStrategyWhitelister();
    /// @dev Thrown when provided `shares` amount is too high.
    error SharesAmountTooHigh();
    /// @dev Thrown when provided `shares` amount is zero.
    error SharesAmountZero();
    /// @dev Thrown when provided `staker` address is null.
    error StakerAddressZero();
    /// @dev Thrown when provided `strategy` not found.
    error StrategyNotFound();
    /// @dev Thrown when attempting to deposit to a non-whitelisted strategy.
    error StrategyNotWhitelisted();
    /// @dev Thrown when attempting to add a strategy that is already in the operator set's burn or redistributable shares.
    error StrategyAlreadyInSlash();
    /// @dev Thrown when attempting to clear burn or redistributable shares before the slash resolution delay has elapsed.
    error SlashResolutionDelayNotElapsed();
}

interface IStrategyManagerEvents {
    /// @notice Emitted when a new deposit occurs on behalf of `staker`.
    /// @param staker Is the staker who is depositing funds into EigenLayer.
    /// @param strategy Is the strategy that `staker` has deposited into.
    /// @param shares Is the number of new shares `staker` has been granted in `strategy`.
    event Deposit(address staker, IStrategy strategy, uint256 shares);

    /// @notice Emitted when the `strategyWhitelister` is changed
    event StrategyWhitelisterChanged(address previousAddress, address newAddress);

    /// @notice Emitted when a strategy is added to the approved list of strategies for deposit
    event StrategyAddedToDepositWhitelist(IStrategy strategy);

    /// @notice Emitted when a strategy is removed from the approved list of strategies for deposit
    event StrategyRemovedFromDepositWhitelist(IStrategy strategy);

    /// @notice Emitted when an operator is slashed and shares to be burned or redistributed are increased
    event BurnOrRedistributableSharesIncreased(
        OperatorSet operatorSet,
        uint256 slashId,
        IStrategy strategy,
        uint256 shares
    );

    /// @notice Emitted when the slash resolution block is set for an operator set slash
    event SlashResolutionBlockSet(OperatorSet operatorSet, uint256 slashId, uint32 resolutionBlock);

    /// @notice Emitted when shares marked for burning or redistribution are decreased and transferred to the operator set's redistribution recipient
    event BurnOrRedistributableSharesDecreased(
        OperatorSet operatorSet,
        uint256 slashId,
        IStrategy strategy,
        uint256 shares
    );

    /// @notice Emitted when shares are burnt
    /// @dev This event is only emitted in the pre-redistribution slash path
    event BurnableSharesDecreased(IStrategy strategy, uint256 shares);
}

/// @title Interface for the primary entrypoint for funds into EigenLayer.
/// @author Layr Labs, Inc.
/// @notice Terms of Service: https://docs.eigenlayer.xyz/overview/terms-of-service
/// @notice See the `StrategyManager` contract itself for implementation details.
interface IStrategyManager is IStrategyManagerErrors, IStrategyManagerEvents, IShareManager {
    /// @notice Initializes the strategy manager contract. Sets the `pauserRegistry` (currently **not** modifiable after being set),
    /// and transfers contract ownership to the specified `initialOwner`.
    /// @param initialOwner Ownership of this contract is transferred to this address.
    /// @param initialStrategyWhitelister The initial value of `strategyWhitelister` to set.
    /// @param initialPausedStatus The initial value of `_paused` to set.
    function initialize(
        address initialOwner,
        address initialStrategyWhitelister,
        uint256 initialPausedStatus
    ) external;

    /// @notice Deposits `amount` of `token` into the specified `strategy` and credits shares to the caller
    /// @param strategy the strategy that handles `token`
    /// @param token the token from which the `amount` will be transferred
    /// @param amount the number of tokens to deposit
    /// @return depositShares the number of deposit shares credited to the caller
    /// @dev The caller must have previously approved this contract to transfer at least `amount` of `token` on their behalf.
    ///
    /// WARNING: Be extremely cautious when depositing tokens that do not strictly adhere to ERC20 standards.
    /// Tokens that diverge significantly from ERC20 norms can cause unexpected behavior in token balances for
    /// that strategy, e.g. ERC-777 tokens allowing cross-contract reentrancy.
    function depositIntoStrategy(
        IStrategy strategy,
        IERC20 token,
        uint256 amount
    ) external returns (uint256 depositShares);

    /// @notice Deposits `amount` of `token` into the specified `strategy` and credits shares to the `staker`
    /// Note tokens are transferred from `msg.sender`, NOT from `staker`. This method allows the caller, using a
    /// signature, to deposit their tokens to another staker's balance.
    /// @param strategy the strategy that handles `token`
    /// @param token the token from which the `amount` will be transferred
    /// @param amount the number of tokens to transfer from the caller to the strategy
    /// @param staker the staker that the deposited assets will be credited to
    /// @param expiry the timestamp at which the signature expires
    /// @param signature a valid ECDSA or EIP-1271 signature from `staker`
    /// @return depositShares the number of deposit shares credited to `staker`
    /// @dev The caller must have previously approved this contract to transfer at least `amount` of `token` on their behalf.
    ///
    /// WARNING: Be extremely cautious when depositing tokens that do not strictly adhere to ERC20 standards.
    /// Tokens that diverge significantly from ERC20 norms can cause unexpected behavior in token balances for
    /// that strategy, e.g. ERC-777 tokens allowing cross-contract reentrancy.
    function depositIntoStrategyWithSignature(
        IStrategy strategy,
        IERC20 token,
        uint256 amount,
        address staker,
        uint256 expiry,
        bytes memory signature
    ) external returns (uint256 depositShares);

    /// @notice Legacy burn strategy shares for the given strategy by calling into the strategy to transfer
    /// to the default burn address.
    /// @param strategy The strategy to burn shares in.
    /// @dev This function will be DEPRECATED in a release after redistribution
    function burnShares(
        IStrategy strategy
    ) external;

    /// @notice Removes burned shares from storage and transfers the underlying tokens for the slashId to the redistribution recipient.
    /// @dev Reverts if `SLASH_RESOLUTION_DELAY_BLOCKS` has not elapsed since the slash was recorded.
    /// @dev Reverts if clearing is paused via `PAUSED_BURNING_AND_REDISTRIBUTION`.
    /// @param operatorSet The operator set to burn shares in.
    /// @param slashId The slash ID to burn shares in.
    /// @return The amounts of tokens transferred to the redistribution recipient for each strategy
    function clearBurnOrRedistributableShares(
        OperatorSet calldata operatorSet,
        uint256 slashId
    ) external returns (uint256[] memory);

    /// @notice Removes a single strategy's shares from storage and transfers the underlying tokens for the slashId to the redistribution recipient.
    /// @dev Reverts if `SLASH_RESOLUTION_DELAY_BLOCKS` has not elapsed since the slash was recorded.
    /// @dev Reverts if clearing is paused via `PAUSED_BURNING_AND_REDISTRIBUTION`.
    /// @param operatorSet The operator set to burn shares in.
    /// @param slashId The slash ID to burn shares in.
    /// @param strategy The strategy to burn shares in.
    /// @return The amount of tokens transferred to the redistribution recipient for the strategy.
    function clearBurnOrRedistributableSharesByStrategy(
        OperatorSet calldata operatorSet,
        uint256 slashId,
        IStrategy strategy
    ) external returns (uint256);

    /// @notice Returns the strategies and shares that are pending slash resolution for a given slashId.
    /// @dev Shares cannot be cleared until `SLASH_RESOLUTION_DELAY_BLOCKS` has elapsed after the slash.
    /// @param operatorSet The operator set to burn or redistribute shares in.
    /// @param slashId The slash ID to burn or redistribute shares in.
    /// @return The strategies and shares for the given slashId.
    function getBurnOrRedistributableShares(
        OperatorSet calldata operatorSet,
        uint256 slashId
    ) external view returns (IStrategy[] memory, uint256[] memory);

    /// @notice Returns the shares for a given strategy for a given slashId.
    /// @param operatorSet The operator set to burn or redistribute shares in.
    /// @param slashId The slash ID to burn or redistribute shares in.
    /// @param strategy The strategy to get the shares for.
    /// @return The shares for the given strategy for the given slashId.
    /// @dev Returns 0 if the strategy has no pending shares for the given slash.
    function getBurnOrRedistributableShares(
        OperatorSet calldata operatorSet,
        uint256 slashId,
        IStrategy strategy
    ) external view returns (uint256);

    /// @notice Returns the number of strategies pending slash resolution for a given slashId.
    /// @dev Strategies cannot be cleared until `SLASH_RESOLUTION_DELAY_BLOCKS` has elapsed after the slash.
    /// @param operatorSet The operator set to burn or redistribute shares in.
    /// @param slashId The slash ID to burn or redistribute shares in.
    /// @return The number of strategies for the given slashId.
    function getBurnOrRedistributableCount(
        OperatorSet calldata operatorSet,
        uint256 slashId
    ) external view returns (uint256);

    /// @notice Owner-only function to change the `strategyWhitelister` address.
    /// @param newStrategyWhitelister new address for the `strategyWhitelister`.
    function setStrategyWhitelister(
        address newStrategyWhitelister
    ) external;

    /// @notice Owner-only function that adds the provided Strategies to the 'whitelist' of strategies that stakers can deposit into
    /// @param strategiesToWhitelist Strategies that will be added to the `strategyIsWhitelistedForDeposit` mapping (if they aren't in it already)
    function addStrategiesToDepositWhitelist(
        IStrategy[] calldata strategiesToWhitelist
    ) external;

    /// @notice Owner-only function that removes the provided Strategies from the 'whitelist' of strategies that stakers can deposit into
    /// @param strategiesToRemoveFromWhitelist Strategies that will be removed to the `strategyIsWhitelistedForDeposit` mapping (if they are in it)
    function removeStrategiesFromDepositWhitelist(
        IStrategy[] calldata strategiesToRemoveFromWhitelist
    ) external;

    /// @notice Returns bool for whether or not `strategy` is whitelisted for deposit
    function strategyIsWhitelistedForDeposit(
        IStrategy strategy
    ) external view returns (bool);

    /// @notice Get all details on the staker's deposits and corresponding shares
    /// @return (staker's strategies, shares in these strategies)
    function getDeposits(
        address staker
    ) external view returns (IStrategy[] memory, uint256[] memory);

    function getStakerStrategyList(
        address staker
    ) external view returns (IStrategy[] memory);

    /// @notice Simple getter function that returns `stakerStrategyList[staker].length`.
    function stakerStrategyListLength(
        address staker
    ) external view returns (uint256);

    /// @notice Returns the current shares of `user` in `strategy`
    function stakerDepositShares(
        address user,
        IStrategy strategy
    ) external view returns (uint256 shares);

    /// @notice Returns the single, central Delegation contract of EigenLayer
    function delegation() external view returns (IDelegationManager);

    /// @notice Returns the address of the `strategyWhitelister`
    function strategyWhitelister() external view returns (address);

    /// @notice Returns the burnable shares of a strategy
    /// @dev This function will be deprecated in a release after redistribution
    function getBurnableShares(
        IStrategy strategy
    ) external view returns (uint256);

    /// @notice Gets every strategy with burnable shares and the amount of burnable shares in each said strategy
    ///
    /// @dev This function will be deprecated in a release after redistribution
    /// WARNING: This operation can copy the entire storage to memory, which can be quite expensive. This is designed
    /// to mostly be used by view accessors that are queried without any gas fees. Users should keep in mind that
    /// this function has an unbounded cost, and using it as part of a state-changing function may render the function
    /// uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
    function getStrategiesWithBurnableShares() external view returns (address[] memory, uint256[] memory);

    /// @param staker The address of the staker.
    /// @param strategy The strategy to deposit into.
    /// @param token The token to deposit.
    /// @param amount The amount of `token` to deposit.
    /// @param nonce The nonce of the staker.
    /// @param expiry The expiry of the signature.
    /// @return The EIP-712 signable digest hash.
    function calculateStrategyDepositDigestHash(
        address staker,
        IStrategy strategy,
        IERC20 token,
        uint256 amount,
        uint256 nonce,
        uint256 expiry
    ) external view returns (bytes32);

    /// @notice Returns the operator sets that have pending burn or redistributable shares.
    /// @return The operator sets that have pending burn or redistributable shares.
    function getPendingOperatorSets() external view returns (OperatorSet[] memory);

    /// @notice Returns the slash IDs that are pending to be burned or redistributed.
    /// @dev Returns an empty array if the operator set has no pending burn or redistributable shares.
    /// @param operatorSet The operator set to get the pending slash IDs for.
    /// @return The slash IDs that are pending to be burned or redistributed.
    function getPendingSlashIds(
        OperatorSet calldata operatorSet
    ) external view returns (uint256[] memory);

    /// @notice Returns the block number after which the given slash's shares may be cleared.
    /// @dev Returns 0 for slashes recorded before the slash resolution delay was introduced (these clear immediately).
    /// @param operatorSet The operator set the slash belongs to.
    /// @param slashId The slash ID to query.
    /// @return The block number after which clearing is permitted.
    function getSlashResolutionBlock(
        OperatorSet calldata operatorSet,
        uint256 slashId
    ) external view returns (uint32);
}

// Source: src/contracts/libraries/Merkle.sol
// Adapted from OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

/// @dev These functions deal with verification of Merkle Tree proofs.
///
/// WARNING: You should avoid using leaf values that are 64 bytes long prior to
/// hashing, salt the leaves, or hash the leaves with a hash function other than
/// what is used for the Merkle tree's internal nodes. This is because the
/// concatenation of a sorted pair of internal nodes in the Merkle tree could
/// be reinterpreted as a leaf value.
library Merkle {
    /// @notice Thrown when the provided proof was not a multiple of 32, or was empty for SHA256.
    /// @dev Error code: 0x4dc5f6a4
    error InvalidProofLength();

    /// @notice Thrown when the provided index was outside the max index for the tree.
    /// @dev Error code: 0x63df8171
    error InvalidIndex();

    /// @notice Thrown when the provided leaves' length was not a power of two.
    /// @dev Error code: 0xf6558f51
    error LeavesNotPowerOfTwo();

    /// @notice Thrown when the provided leaves' length was 0.
    /// @dev Error code: 0xbaec3d9a
    error NoLeaves();

    /// @notice Thrown when the provided leaves' length was insufficient.
    /// @dev Error code: 0xf8ef0367
    /// @dev This is used for the SHA256 Merkle tree, where the tree must have more than 1 leaf.
    error NotEnoughLeaves();

    /// @notice Thrown when the root is empty.
    /// @dev Error code: 0x53ce4ece
    /// @dev Empty roots should never be valid. We prevent them to avoid issues like the Nomad bridge attack: <https://medium.com/nomad-xyz-blog/nomad-bridge-hack-root-cause-analysis-875ad2e5aacd>
    error EmptyRoot();

    /// @notice Verifies that a given leaf is included in a Merkle tree
    /// @param proof The proof of inclusion for the leaf
    /// @param root The root of the Merkle tree
    /// @param leaf The leaf to verify
    /// @param index The index of the leaf in the Merkle tree
    /// @return True if the leaf is included in the Merkle tree, false otherwise
    /// @dev A `proof` is valid if and only if the rebuilt hash matches the root of the tree.
    /// @dev Reverts for:
    ///      - InvalidProofLength: proof.length is not a multiple of 32.
    ///      - InvalidIndex: index is not 0 at conclusion of computation (implying outside the max index for the tree).
    function verifyInclusionKeccak(
        bytes memory proof,
        bytes32 root,
        bytes32 leaf,
        uint256 index
    ) internal pure returns (bool) {
        require(root != bytes32(0), EmptyRoot());
        return processInclusionProofKeccak(proof, leaf, index) == root;
    }

    /// @notice Returns the rebuilt hash obtained by traversing a Merkle tree up
    /// from `leaf` using `proof`.
    /// @param proof The proof of inclusion for the leaf
    /// @param leaf The leaf to verify
    /// @param index The index of the leaf in the Merkle tree
    /// @return The rebuilt hash
    /// @dev Reverts for:
    ///      - InvalidProofLength: proof.length is not a multiple of 32.
    ///      - InvalidIndex: index is not 0 at conclusion of computation (implying outside the max index for the tree).
    /// @dev The tree is built assuming `leaf` is the 0 indexed `index`'th leaf from the bottom left of the tree.
    function processInclusionProofKeccak(
        bytes memory proof,
        bytes32 leaf,
        uint256 index
    ) internal pure returns (bytes32) {
        if (proof.length == 0) {
            return leaf;
        }

        require(proof.length % 32 == 0, InvalidProofLength());

        bytes32 computedHash = leaf;
        for (uint256 i = 32; i <= proof.length; i += 32) {
            if (index % 2 == 0) {
                // if index is even, then computedHash is a left sibling
                assembly {
                    mstore(0x00, computedHash)
                    mstore(0x20, mload(add(proof, i)))
                    computedHash := keccak256(0x00, 0x40)
                    index := div(index, 2)
                }
            } else {
                // if index is odd, then computedHash is a right sibling
                assembly {
                    mstore(0x00, mload(add(proof, i)))
                    mstore(0x20, computedHash)
                    computedHash := keccak256(0x00, 0x40)
                    index := div(index, 2)
                }
            }
        }

        // Confirm proof was fully consumed by end of computation
        require(index == 0, InvalidIndex());

        return computedHash;
    }

    /// @notice Verifies that a given leaf is included in a Merkle tree
    /// @param proof The proof of inclusion for the leaf
    /// @param root The root of the Merkle tree
    /// @param leaf The leaf to verify
    /// @param index The index of the leaf in the Merkle tree
    /// @return True if the leaf is included in the Merkle tree, false otherwise
    /// @dev A `proof` is valid if and only if the rebuilt hash matches the root of the tree.
    /// @dev Reverts for:
    ///      - InvalidProofLength: proof.length is 0 or not a multiple of 32.
    ///      - InvalidIndex: index is not 0 at conclusion of computation (implying outside the max index for the tree).
    function verifyInclusionSha256(
        bytes memory proof,
        bytes32 root,
        bytes32 leaf,
        uint256 index
    ) internal view returns (bool) {
        require(root != bytes32(0), EmptyRoot());
        return processInclusionProofSha256(proof, leaf, index) == root;
    }

    /// @notice Returns the rebuilt hash obtained by traversing a Merkle tree up
    /// from `leaf` using `proof`.
    /// @param proof The proof of inclusion for the leaf
    /// @param leaf The leaf to verify
    /// @param index The index of the leaf in the Merkle tree
    /// @return The rebuilt hash
    /// @dev Reverts for:
    ///      - InvalidProofLength: proof.length is 0 or not a multiple of 32.
    ///      - InvalidIndex: index is not 0 at conclusion of computation (implying outside the max index for the tree).
    /// @dev The tree is built assuming `leaf` is the 0 indexed `index`'th leaf from the bottom left of the tree.
    function processInclusionProofSha256(
        bytes memory proof,
        bytes32 leaf,
        uint256 index
    ) internal view returns (bytes32) {
        require(proof.length != 0 && proof.length % 32 == 0, InvalidProofLength());
        bytes32[1] memory computedHash = [leaf];
        for (uint256 i = 32; i <= proof.length; i += 32) {
            if (index % 2 == 0) {
                // if index is even, then computedHash is a left sibling
                assembly {
                    mstore(0x00, mload(computedHash))
                    mstore(0x20, mload(add(proof, i)))
                    if iszero(staticcall(sub(gas(), 2000), 2, 0x00, 0x40, computedHash, 0x20)) {
                        revert(0, 0)
                    }
                    index := div(index, 2)
                }
            } else {
                // if index is odd, then computedHash is a right sibling
                assembly {
                    mstore(0x00, mload(add(proof, i)))
                    mstore(0x20, mload(computedHash))
                    if iszero(staticcall(sub(gas(), 2000), 2, 0x00, 0x40, computedHash, 0x20)) {
                        revert(0, 0)
                    }
                    index := div(index, 2)
                }
            }
        }

        // Confirm proof was fully consumed by end of computation
        require(index == 0, InvalidIndex());

        return computedHash[0];
    }

    /// @notice Returns the Merkle root of a tree created from a set of leaves using SHA-256 as its hash function
    /// @param leaves the leaves of the Merkle tree
    /// @return The computed Merkle root of the tree.
    /// @dev Reverts for:
    ///      - NotEnoughLeaves: leaves.length is less than 2.
    ///      - LeavesNotPowerOfTwo: leaves.length is not a power of two.
    /// @dev Unlike the Keccak version, this function does not allow a single-leaf tree.
    function merkleizeSha256(
        bytes32[] memory leaves
    ) internal pure returns (bytes32) {
        require(leaves.length > 1, NotEnoughLeaves());
        require(isPowerOfTwo(leaves.length), LeavesNotPowerOfTwo());

        // There are half as many nodes in the layer above the leaves
        uint256 numNodesInLayer = leaves.length / 2;
        // Create a layer to store the internal nodes
        bytes32[] memory layer = new bytes32[](numNodesInLayer);
        // Fill the layer with the pairwise hashes of the leaves
        for (uint256 i = 0; i < numNodesInLayer; i++) {
            layer[i] = sha256(abi.encodePacked(leaves[2 * i], leaves[2 * i + 1]));
        }

        // While we haven't computed the root
        while (numNodesInLayer != 1) {
            // The next layer above has half as many nodes
            numNodesInLayer /= 2;
            // Overwrite the first numNodesInLayer nodes in layer with the pairwise hashes of their children
            for (uint256 i = 0; i < numNodesInLayer; i++) {
                layer[i] = sha256(abi.encodePacked(layer[2 * i], layer[2 * i + 1]));
            }
        }
        // The first node in the layer is the root
        return layer[0];
    }

    /// @notice Returns the Merkle root of a tree created from a set of leaves using Keccak as its hash function
    /// @param leaves the leaves of the Merkle tree
    /// @return The computed Merkle root of the tree.
    /// @dev Reverts for:
    ///      - NoLeaves: leaves.length is 0.
    function merkleizeKeccak(
        bytes32[] memory leaves
    ) internal pure returns (bytes32) {
        require(leaves.length > 0, NoLeaves());

        uint256 numNodesInLayer;
        if (!isPowerOfTwo(leaves.length)) {
            // Pad to the next power of 2
            numNodesInLayer = 1;
            while (numNodesInLayer < leaves.length) {
                numNodesInLayer *= 2;
            }
        } else {
            numNodesInLayer = leaves.length;
        }

        // Create a layer to store the internal nodes
        bytes32[] memory layer = new bytes32[](numNodesInLayer);
        for (uint256 i = 0; i < leaves.length; i++) {
            layer[i] = leaves[i];
        }

        // While we haven't computed the root
        while (numNodesInLayer != 1) {
            // The next layer above has half as many nodes
            numNodesInLayer /= 2;
            // Overwrite the first numNodesInLayer nodes in layer with the pairwise hashes of their children
            for (uint256 i = 0; i < numNodesInLayer; i++) {
                layer[i] = keccak256(abi.encodePacked(layer[2 * i], layer[2 * i + 1]));
            }
        }
        // The first node in the layer is the root
        return layer[0];
    }

    /// @notice Returns the Merkle proof for a given index in a tree created from a set of leaves using Keccak as its hash function
    /// @param leaves the leaves of the Merkle tree
    /// @param index the index of the leaf to get the proof for
    /// @return proof The computed Merkle proof for the leaf at index.
    /// @dev Reverts for:
    ///      - InvalidIndex: index is outside the max index for the tree.
    function getProofKeccak(
        bytes32[] memory leaves,
        uint256 index
    ) internal pure returns (bytes memory proof) {
        require(leaves.length > 0, NoLeaves());
        // TODO: very inefficient, use ZERO_HASHES
        // pad to the next power of 2
        uint256 numNodesInLayer = 1;
        while (numNodesInLayer < leaves.length) {
            numNodesInLayer *= 2;
        }
        bytes32[] memory layer = new bytes32[](numNodesInLayer);
        for (uint256 i = 0; i < leaves.length; i++) {
            layer[i] = leaves[i];
        }

        if (index >= layer.length) revert InvalidIndex();

        // While we haven't computed the root
        while (numNodesInLayer != 1) {
            // Flip the least significant bit of index to get the sibling index
            uint256 siblingIndex = index ^ 1;
            // Add the sibling to the proof
            proof = abi.encodePacked(proof, layer[siblingIndex]);
            index /= 2;

            // The next layer above has half as many nodes
            numNodesInLayer /= 2;
            // Overwrite the first numNodesInLayer nodes in layer with the pairwise hashes of their children
            for (uint256 i = 0; i < numNodesInLayer; i++) {
                layer[i] = keccak256(abi.encodePacked(layer[2 * i], layer[2 * i + 1]));
            }
        }
    }

    /// @notice Returns the Merkle proof for a given index in a tree created from a set of leaves using SHA-256 as its hash function
    /// @param leaves the leaves of the Merkle tree
    /// @param index the index of the leaf to get the proof for
    /// @return proof The computed Merkle proof for the leaf at index.
    /// @dev Reverts for:
    ///      - NotEnoughLeaves: leaves.length is less than 2.
    /// @dev Unlike the Keccak version, this function does not allow a single-leaf proof.
    function getProofSha256(
        bytes32[] memory leaves,
        uint256 index
    ) internal pure returns (bytes memory proof) {
        require(leaves.length > 1, NotEnoughLeaves());
        // TODO: very inefficient, use ZERO_HASHES
        // pad to the next power of 2
        uint256 numNodesInLayer = 1;
        while (numNodesInLayer < leaves.length) {
            numNodesInLayer *= 2;
        }
        bytes32[] memory layer = new bytes32[](numNodesInLayer);
        for (uint256 i = 0; i < leaves.length; i++) {
            layer[i] = leaves[i];
        }

        if (index >= layer.length) revert InvalidIndex();

        // While we haven't computed the root
        while (numNodesInLayer != 1) {
            // Flip the least significant bit of index to get the sibling index
            uint256 siblingIndex = index ^ 1;
            // Add the sibling to the proof
            proof = abi.encodePacked(proof, layer[siblingIndex]);
            index /= 2;

            // The next layer above has half as many nodes
            numNodesInLayer /= 2;
            // Overwrite the first numNodesInLayer nodes in layer with the pairwise hashes of their children
            for (uint256 i = 0; i < numNodesInLayer; i++) {
                layer[i] = sha256(abi.encodePacked(layer[2 * i], layer[2 * i + 1]));
            }
        }
    }

    /// @notice Returns whether the input is a power of two
    /// @param value the value to check
    /// @return True if the input is a power of two, false otherwise
    function isPowerOfTwo(
        uint256 value
    ) internal pure returns (bool) {
        return value != 0 && (value & (value - 1)) == 0;
    }
}

// Source: src/contracts/libraries/Endian.sol
library Endian {
    /// @notice Converts a little endian-formatted uint64 to a big endian-formatted uint64
    /// @param lenum little endian-formatted uint64 input, provided as 'bytes32' type
    /// @return n The big endian-formatted uint64
    /// @dev Note that the input is formatted as a 'bytes32' type (i.e. 256 bits), but it is immediately truncated to a uint64 (i.e. 64 bits)
    /// through a right-shift/shr operation.
    function fromLittleEndianUint64(
        bytes32 lenum
    ) internal pure returns (uint64 n) {
        // the number needs to be stored in little-endian encoding (ie in bytes 0-8)
        n = uint64(uint256(lenum >> 192));
        // forgefmt: disable-next-item
        return (n >> 56) | 
            ((0x00FF000000000000 & n) >> 40) | 
            ((0x0000FF0000000000 & n) >> 24) | 
            ((0x000000FF00000000 & n) >> 8)  | 
            ((0x00000000FF000000 & n) << 8)  | 
            ((0x0000000000FF0000 & n) << 24) | 
            ((0x000000000000FF00 & n) << 40) | 
            ((0x00000000000000FF & n) << 56);
    }
}

// Source: src/contracts/libraries/BeaconChainProofs.sol
//Utility library for parsing and PHASE0 beacon chain block headers
//SSZ Spec: https://github.com/ethereum/consensus-specs/blob/dev/ssz/simple-serialize.md#merkleization
//BeaconBlockHeader Spec: https://github.com/ethereum/consensus-specs/blob/dev/specs/phase0/beacon-chain.md#beaconblockheader
//BeaconState Spec: https://github.com/ethereum/consensus-specs/blob/dev/specs/phase0/beacon-chain.md#beaconstate
library BeaconChainProofs {
    /// @dev Thrown when a proof is invalid.
    error InvalidProof();
    /// @dev Thrown when a proof with an invalid length is provided.
    error InvalidProofLength();
    /// @dev Thrown when a validator fields length is invalid.
    error InvalidValidatorFieldsLength();

    /// @notice Heights of various merkle trees in the beacon chain
    ///         beaconBlockRoot
    ///                |                              HEIGHT: BEACON_BLOCK_HEADER_TREE_HEIGHT
    ///         beaconStateRoot
    ///        /               \                      HEIGHT: BEACON_STATE_TREE_HEIGHT
    /// validatorContainerRoot, balanceContainerRoot
    ///          |                       |            HEIGHT: BALANCE_TREE_HEIGHT
    ///          |              individual balances
    ///          |                                    HEIGHT: VALIDATOR_TREE_HEIGHT
    /// individual validators
    uint256 internal constant BEACON_BLOCK_HEADER_TREE_HEIGHT = 3;
    uint256 internal constant DENEB_BEACON_STATE_TREE_HEIGHT = 5;
    uint256 internal constant PECTRA_BEACON_STATE_TREE_HEIGHT = 6;
    uint256 internal constant BALANCE_TREE_HEIGHT = 38;
    uint256 internal constant VALIDATOR_TREE_HEIGHT = 40;

    /// @notice Index of the beaconStateRoot in the `BeaconBlockHeader` container
    ///
    /// BeaconBlockHeader = [..., state_root, ...]
    ///                      0...      3
    ///
    /// (See https://github.com/ethereum/consensus-specs/blob/dev/specs/phase0/beacon-chain.md#beaconblockheader)
    uint256 internal constant STATE_ROOT_INDEX = 3;

    /// @notice Indices for fields in the `BeaconState` container
    ///
    /// BeaconState = [..., validators, balances, ...]
    ///                0...     11         12
    ///
    /// (See https://github.com/ethereum/consensus-specs/blob/dev/specs/capella/beacon-chain.md#beaconstate)
    uint256 internal constant VALIDATOR_CONTAINER_INDEX = 11;
    uint256 internal constant BALANCE_CONTAINER_INDEX = 12;

    /// @notice Number of fields in the `Validator` container
    /// (See https://github.com/ethereum/consensus-specs/blob/dev/specs/phase0/beacon-chain.md#validator)
    uint256 internal constant VALIDATOR_FIELDS_LENGTH = 8;

    /// @notice Indices for fields in the `Validator` container
    uint256 internal constant VALIDATOR_PUBKEY_INDEX = 0;
    uint256 internal constant VALIDATOR_WITHDRAWAL_CREDENTIALS_INDEX = 1;
    uint256 internal constant VALIDATOR_BALANCE_INDEX = 2;
    uint256 internal constant VALIDATOR_SLASHED_INDEX = 3;
    uint256 internal constant VALIDATOR_ACTIVATION_EPOCH_INDEX = 5;
    uint256 internal constant VALIDATOR_EXIT_EPOCH_INDEX = 6;

    /// @notice Slot/Epoch timings
    uint64 internal constant SECONDS_PER_SLOT = 12;
    uint64 internal constant SLOTS_PER_EPOCH = 32;
    uint64 internal constant SECONDS_PER_EPOCH = SLOTS_PER_EPOCH * SECONDS_PER_SLOT;

    /// @notice `FAR_FUTURE_EPOCH` is used as the default value for certain `Validator`
    /// fields when a `Validator` is first created on the beacon chain
    uint64 internal constant FAR_FUTURE_EPOCH = type(uint64).max;
    bytes8 internal constant UINT64_MASK = 0xffffffffffffffff;

    /// @notice The beacon chain version to validate against
    enum ProofVersion {
        DENEB,
        PECTRA
    }

    /// @notice Contains a beacon state root and a merkle proof verifying its inclusion under a beacon block root
    struct StateRootProof {
        bytes32 beaconStateRoot;
        bytes proof;
    }

    /// @notice Contains a validator's fields and a merkle proof of their inclusion under a beacon state root
    struct ValidatorProof {
        bytes32[] validatorFields;
        bytes proof;
    }

    /// @notice Contains a beacon balance container root and a proof of this root under a beacon block root
    struct BalanceContainerProof {
        bytes32 balanceContainerRoot;
        bytes proof;
    }

    /// @notice Contains a validator balance root and a proof of its inclusion under a balance container root
    struct BalanceProof {
        bytes32 pubkeyHash;
        bytes32 balanceRoot;
        bytes proof;
    }

    ///
    ///              VALIDATOR FIELDS -> BEACON STATE ROOT -> BEACON BLOCK ROOT
    ///

    /// @notice Verify a merkle proof of the beacon state root against a beacon block root
    /// @param beaconBlockRoot merkle root of the beacon block
    /// @param proof the beacon state root and merkle proof of its inclusion under `beaconBlockRoot`
    function verifyStateRoot(
        bytes32 beaconBlockRoot,
        StateRootProof calldata proof
    ) internal view {
        require(proof.proof.length == 32 * (BEACON_BLOCK_HEADER_TREE_HEIGHT), InvalidProofLength());

        /// This merkle proof verifies the `beaconStateRoot` under the `beaconBlockRoot`
        /// - beaconBlockRoot
        /// |                            HEIGHT: BEACON_BLOCK_HEADER_TREE_HEIGHT
        /// -- beaconStateRoot
        require(
            Merkle.verifyInclusionSha256({
                proof: proof.proof,
                root: beaconBlockRoot,
                leaf: proof.beaconStateRoot,
                index: STATE_ROOT_INDEX
            }),
            InvalidProof()
        );
    }

    /// @notice Verify a merkle proof of a validator container against a `beaconStateRoot`
    /// @dev This proof starts at a validator's container root, proves through the validator container root,
    /// and continues proving to the root of the `BeaconState`
    /// @dev See https://eth2book.info/capella/part3/containers/dependencies/#validator for info on `Validator` containers
    /// @dev See https://eth2book.info/capella/part3/containers/state/#beaconstate for info on `BeaconState` containers
    /// @param beaconStateRoot merkle root of the `BeaconState` container
    /// @param validatorFields an individual validator's fields. These are merklized to form a `validatorRoot`,
    /// which is used as the leaf to prove against `beaconStateRoot`
    /// @param validatorFieldsProof a merkle proof of inclusion of `validatorFields` under `beaconStateRoot`
    /// @param validatorIndex the validator's unique index
    function verifyValidatorFields(
        ProofVersion proofVersion,
        bytes32 beaconStateRoot,
        bytes32[] calldata validatorFields,
        bytes calldata validatorFieldsProof,
        uint40 validatorIndex
    ) internal view {
        require(validatorFields.length == VALIDATOR_FIELDS_LENGTH, InvalidValidatorFieldsLength());

        uint256 beaconStateTreeHeight = getBeaconStateTreeHeight(proofVersion);

        /// Note: the reason we use `VALIDATOR_TREE_HEIGHT + 1` here is because the merklization process for
        /// this container includes hashing the root of the validator tree with the length of the validator list
        require(
            validatorFieldsProof.length == 32 * ((VALIDATOR_TREE_HEIGHT + 1) + beaconStateTreeHeight),
            InvalidProofLength()
        );

        // Merkleize `validatorFields` to get the leaf to prove
        bytes32 validatorRoot = Merkle.merkleizeSha256(validatorFields);

        /// This proof combines two proofs, so its index accounts for the relative position of leaves in two trees:
        /// - beaconStateRoot
        /// |                            HEIGHT: BEACON_STATE_TREE_HEIGHT
        /// -- validatorContainerRoot
        /// |                            HEIGHT: VALIDATOR_TREE_HEIGHT + 1
        /// ---- validatorRoot
        uint256 index = (VALIDATOR_CONTAINER_INDEX << (VALIDATOR_TREE_HEIGHT + 1)) | uint256(validatorIndex);

        require(
            Merkle.verifyInclusionSha256({
                proof: validatorFieldsProof,
                root: beaconStateRoot,
                leaf: validatorRoot,
                index: index
            }),
            InvalidProof()
        );
    }

    ///
    ///          VALIDATOR BALANCE -> BALANCE CONTAINER ROOT -> BEACON BLOCK ROOT
    ///

    /// @notice Verify a merkle proof of the beacon state's balances container against the beacon block root
    /// @dev This proof starts at the balance container root, proves through the beacon state root, and
    /// continues proving through the beacon block root. As a result, this proof will contain elements
    /// of a `StateRootProof` under the same block root, with the addition of proving the balances field
    /// within the beacon state.
    /// @dev This is used to make checkpoint proofs more efficient, as a checkpoint will verify multiple balances
    /// against the same balance container root.
    /// @param beaconBlockRoot merkle root of the beacon block
    /// @param proof a beacon balance container root and merkle proof of its inclusion under `beaconBlockRoot`
    function verifyBalanceContainer(
        ProofVersion proofVersion,
        bytes32 beaconBlockRoot,
        BalanceContainerProof calldata proof
    ) internal view {
        uint256 beaconStateTreeHeight = getBeaconStateTreeHeight(proofVersion);

        require(
            proof.proof.length == 32 * (BEACON_BLOCK_HEADER_TREE_HEIGHT + beaconStateTreeHeight), InvalidProofLength()
        );

        /// This proof combines two proofs, so its index accounts for the relative position of leaves in two trees:
        /// - beaconBlockRoot
        /// |                            HEIGHT: BEACON_BLOCK_HEADER_TREE_HEIGHT
        /// -- beaconStateRoot
        /// |                            HEIGHT: BEACON_STATE_TREE_HEIGHT
        /// ---- balancesContainerRoot
        uint256 index = (STATE_ROOT_INDEX << (beaconStateTreeHeight)) | BALANCE_CONTAINER_INDEX;

        require(
            Merkle.verifyInclusionSha256({
                proof: proof.proof,
                root: beaconBlockRoot,
                leaf: proof.balanceContainerRoot,
                index: index
            }),
            InvalidProof()
        );
    }

    /// @notice Verify a merkle proof of a validator's balance against the beacon state's `balanceContainerRoot`
    /// @param balanceContainerRoot the merkle root of all validators' current balances
    /// @param validatorIndex the index of the validator whose balance we are proving
    /// @param proof the validator's associated balance root and a merkle proof of inclusion under `balanceContainerRoot`
    /// @return validatorBalanceGwei the validator's current balance (in gwei)
    function verifyValidatorBalance(
        bytes32 balanceContainerRoot,
        uint40 validatorIndex,
        BalanceProof calldata proof
    ) internal view returns (uint64 validatorBalanceGwei) {
        /// Note: the reason we use `BALANCE_TREE_HEIGHT + 1` here is because the merklization process for
        /// this container includes hashing the root of the balances tree with the length of the balances list
        require(proof.proof.length == 32 * (BALANCE_TREE_HEIGHT + 1), InvalidProofLength());

        /// When merkleized, beacon chain balances are combined into groups of 4 called a `balanceRoot`. The merkle
        /// proof here verifies that this validator's `balanceRoot` is included in the `balanceContainerRoot`
        /// - balanceContainerRoot
        /// |                            HEIGHT: BALANCE_TREE_HEIGHT
        /// -- balanceRoot
        uint256 balanceIndex = uint256(validatorIndex / 4);

        require(
            Merkle.verifyInclusionSha256({
                proof: proof.proof,
                root: balanceContainerRoot,
                leaf: proof.balanceRoot,
                index: balanceIndex
            }),
            InvalidProof()
        );

        /// Extract the individual validator's balance from the `balanceRoot`
        return getBalanceAtIndex(proof.balanceRoot, validatorIndex);
    }

    /// @notice Parses a balanceRoot to get the uint64 balance of a validator.
    /// @dev During merkleization of the beacon state balance tree, four uint64 values are treated as a single
    /// leaf in the merkle tree. We use validatorIndex % 4 to determine which of the four uint64 values to
    /// extract from the balanceRoot.
    /// @param balanceRoot is the combination of 4 validator balances being proven for
    /// @param validatorIndex is the index of the validator being proven for
    /// @return The validator's balance, in Gwei
    function getBalanceAtIndex(
        bytes32 balanceRoot,
        uint40 validatorIndex
    ) internal pure returns (uint64) {
        uint256 bitShiftAmount = (validatorIndex % 4) * 64;
        return Endian.fromLittleEndianUint64(bytes32((uint256(balanceRoot) << bitShiftAmount)));
    }

    /// @notice Indices for fields in the `Validator` container:
    /// 0: pubkey
    /// 1: withdrawal credentials
    /// 2: effective balance
    /// 3: slashed?
    /// 4: activation eligibility epoch
    /// 5: activation epoch
    /// 6: exit epoch
    /// 7: withdrawable epoch
    ///
    /// (See https://github.com/ethereum/consensus-specs/blob/dev/specs/phase0/beacon-chain.md#validator)

    /// @dev Retrieves a validator's pubkey hash
    function getPubkeyHash(
        bytes32[] memory validatorFields
    ) internal pure returns (bytes32) {
        return validatorFields[VALIDATOR_PUBKEY_INDEX];
    }

    /// @dev Retrieves a validator's withdrawal credentials
    function getWithdrawalCredentials(
        bytes32[] memory validatorFields
    ) internal pure returns (bytes32) {
        return validatorFields[VALIDATOR_WITHDRAWAL_CREDENTIALS_INDEX];
    }

    /// @dev Retrieves a validator's effective balance (in gwei)
    function getEffectiveBalanceGwei(
        bytes32[] memory validatorFields
    ) internal pure returns (uint64) {
        return Endian.fromLittleEndianUint64(validatorFields[VALIDATOR_BALANCE_INDEX]);
    }

    /// @dev Retrieves a validator's activation epoch
    function getActivationEpoch(
        bytes32[] memory validatorFields
    ) internal pure returns (uint64) {
        return Endian.fromLittleEndianUint64(validatorFields[VALIDATOR_ACTIVATION_EPOCH_INDEX]);
    }

    /// @dev Retrieves true IFF a validator is marked slashed
    function isValidatorSlashed(
        bytes32[] memory validatorFields
    ) internal pure returns (bool) {
        return validatorFields[VALIDATOR_SLASHED_INDEX] != 0;
    }

    /// @dev Retrieves a validator's exit epoch
    function getExitEpoch(
        bytes32[] memory validatorFields
    ) internal pure returns (uint64) {
        return Endian.fromLittleEndianUint64(validatorFields[VALIDATOR_EXIT_EPOCH_INDEX]);
    }

    /// @dev We check if the proofTimestamp is <= pectraForkTimestamp because a `proofTimestamp` at the `pectraForkTimestamp`
    ///      is considered to be Pre-Pectra given the EIP-4788 oracle returns the parent block.
    function getBeaconStateTreeHeight(
        ProofVersion proofVersion
    ) internal pure returns (uint256) {
        return proofVersion == ProofVersion.DENEB ? DENEB_BEACON_STATE_TREE_HEIGHT : PECTRA_BEACON_STATE_TREE_HEIGHT;
    }
}

// Source: src/contracts/interfaces/IEigenPod.sol
interface IEigenPodErrors {
    /// @dev Thrown when msg.sender is not the EPM.
    error OnlyEigenPodManager();
    /// @dev Thrown when msg.sender is not the pod owner.
    error OnlyEigenPodOwner();
    /// @dev Thrown when msg.sender is not owner or the proof submitter.
    error OnlyEigenPodOwnerOrProofSubmitter();
    /// @dev Thrown when attempting an action that is currently paused.
    error CurrentlyPaused();

    /// Invalid Inputs

    /// @dev Thrown when an address of zero is provided.
    error InputAddressZero();
    /// @dev Thrown when two array parameters have mismatching lengths.
    error InputArrayLengthMismatch();
    /// @dev Thrown when `validatorPubKey` length is not equal to 48-bytes.
    error InvalidPubKeyLength();
    /// @dev Thrown when provided timestamp is out of range.
    error TimestampOutOfRange();

    /// Checkpoints

    /// @dev Thrown when no active checkpoints are found.
    error NoActiveCheckpoint();
    /// @dev Thrown if an uncompleted checkpoint exists.
    error CheckpointAlreadyActive();
    /// @dev Thrown if there's not a balance available to checkpoint.
    error NoBalanceToCheckpoint();
    /// @dev Thrown when attempting to create a checkpoint twice within a given block.
    error CannotCheckpointTwiceInSingleBlock();

    /// Withdrawing

    /// @dev Thrown when amount exceeds `restakedExecutionLayerGwei`.
    error InsufficientWithdrawableBalance();

    /// Validator Status

    /// @dev Thrown when a validator's withdrawal credentials have already been verified.
    error CredentialsAlreadyVerified();
    /// @dev Thrown if the provided proof is not valid for this EigenPod.
    error WithdrawalCredentialsNotForEigenPod();
    /// @dev Thrown when a validator is not in the ACTIVE status in the pod.
    error ValidatorNotActiveInPod();
    /// @dev Thrown when validator is not active yet on the beacon chain.
    error ValidatorInactiveOnBeaconChain();
    /// @dev Thrown if a validator is exiting the beacon chain.
    error ValidatorIsExitingBeaconChain();
    /// @dev Thrown when a validator has not been slashed on the beacon chain.
    error ValidatorNotSlashedOnBeaconChain();

    /// Consolidation and Withdrawal Requests

    /// @dev Thrown when a predeploy request is initiated with insufficient msg.value
    error InsufficientFunds();
    /// @dev Thrown when calling the predeploy fails
    error PredeployFailed();
    /// @dev Thrown when querying a predeploy for its current fee fails
    error FeeQueryFailed();

    /// Misc

    /// @dev Thrown when an invalid block root is returned by the EIP-4788 oracle.
    error InvalidEIP4788Response();
    /// @dev Thrown when attempting to send an invalid amount to the beacon deposit contract.
    error MsgValueNot32ETH();
    /// @dev Thrown when provided `beaconTimestamp` is too far in the past.
    error BeaconTimestampTooFarInPast();
    /// @dev Thrown when provided `beaconTimestamp` is before the last checkpoint
    error BeaconTimestampBeforeLatestCheckpoint();
    /// @dev Thrown when the pectraForkTimestamp returned from the EigenPodManager is zero
    error ForkTimestampZero();
}

interface IEigenPodTypes {
    enum VALIDATOR_STATUS {
        INACTIVE, // doesnt exist
        ACTIVE, // staked on ethpos and withdrawal credentials are pointed to the EigenPod
        WITHDRAWN // withdrawn from the Beacon Chain
    }

    /// @param validatorIndex index of the validator on the beacon chain
    /// @param restakedBalanceGwei amount of beacon chain ETH restaked on EigenLayer in gwei
    /// @param lastCheckpointedAt timestamp of the validator's most recent balance update
    /// @param status last recorded status of the validator
    struct ValidatorInfo {
        uint64 validatorIndex;
        uint64 restakedBalanceGwei;
        uint64 lastCheckpointedAt;
        VALIDATOR_STATUS status;
    }

    struct Checkpoint {
        bytes32 beaconBlockRoot;
        uint24 proofsRemaining;
        uint64 podBalanceGwei;
        int64 balanceDeltasGwei;
        uint64 prevBeaconBalanceGwei;
    }

    /// @param srcPubkey the pubkey of the source validator for the consolidation
    /// @param targetPubkey the pubkey of the target validator for the consolidation
    /// @dev Note that if srcPubkey == targetPubkey, this is a "switch request," and will
    /// change the validator's withdrawal credential type from 0x01 to 0x02.
    /// For more notes on usage, see `requestConsolidation`
    struct ConsolidationRequest {
        bytes srcPubkey;
        bytes targetPubkey;
    }

    /// @param pubkey the pubkey of the validator to withdraw from
    /// @param amountGwei the amount (in gwei) to withdraw from the beacon chain to the pod
    /// @dev Note that if amountGwei == 0, this is a "full exit request," and will fully exit
    /// the validator to the pod.
    /// For more notes on usage, see `requestWithdrawal`
    struct WithdrawalRequest {
        bytes pubkey;
        uint64 amountGwei;
    }
}

interface IEigenPodEvents is IEigenPodTypes {
    /// @notice Emitted when an ETH validator stakes via this eigenPod
    event EigenPodStaked(bytes32 pubkeyHash);

    /// @notice Emitted when a pod owner updates the proof submitter address
    event ProofSubmitterUpdated(address prevProofSubmitter, address newProofSubmitter);

    /// @notice Emitted when an ETH validator's withdrawal credentials are successfully verified to be pointed to this eigenPod
    event ValidatorRestaked(bytes32 pubkeyHash);

    /// @notice Emitted when an ETH validator's  balance is proven to be updated.  Here newValidatorBalanceGwei
    //  is the validator's balance that is credited on EigenLayer.
    event ValidatorBalanceUpdated(bytes32 pubkeyHash, uint64 balanceTimestamp, uint64 newValidatorBalanceGwei);

    /// @notice Emitted when restaked beacon chain ETH is withdrawn from the eigenPod.
    event RestakedBeaconChainETHWithdrawn(address indexed recipient, uint256 amount);

    /// @notice Emitted when ETH is received via the `receive` fallback
    event NonBeaconChainETHReceived(uint256 amountReceived);

    /// @notice Emitted when a checkpoint is created
    event CheckpointCreated(
        uint64 indexed checkpointTimestamp,
        bytes32 indexed beaconBlockRoot,
        uint256 validatorCount
    );

    /// @notice Emitted when a checkpoint is finalized
    event CheckpointFinalized(uint64 indexed checkpointTimestamp, int256 totalShareDeltaWei);

    /// @notice Emitted when a validator is proven for a given checkpoint
    event ValidatorCheckpointed(uint64 indexed checkpointTimestamp, bytes32 indexed pubkeyHash);

    /// @notice Emitted when a validator is proven to have 0 balance at a given checkpoint
    event ValidatorWithdrawn(uint64 indexed checkpointTimestamp, bytes32 indexed pubkeyHash);

    /// @notice Emitted when a consolidation request is initiated where source == target
    event SwitchToCompoundingRequested(bytes32 indexed validatorPubkeyHash);

    /// @notice Emitted when a standard consolidation request is initiated
    event ConsolidationRequested(bytes32 indexed sourcePubkeyHash, bytes32 indexed targetPubkeyHash);

    /// @notice Emitted when a withdrawal request is initiated where request.amountGwei == 0
    event ExitRequested(bytes32 indexed validatorPubkeyHash);

    /// @notice Emitted when a partial withdrawal request is initiated
    event WithdrawalRequested(bytes32 indexed validatorPubkeyHash, uint64 withdrawalAmountGwei);
}

/// @title The implementation contract used for restaking beacon chain ETH on EigenLayer
/// @author Layr Labs, Inc.
/// @notice Terms of Service: https://docs.eigenlayer.xyz/overview/terms-of-service
/// @dev Note that all beacon chain balances are stored as gwei within the beacon chain datastructures. We choose
///   to account balances in terms of gwei in the EigenPod contract and convert to wei when making calls to other contracts
interface IEigenPod is IEigenPodErrors, IEigenPodEvents {
    /// @notice Used to initialize the pointers to contracts crucial to the pod's functionality, in beacon proxy construction from EigenPodManager
    function initialize(
        address owner
    ) external;

    /// @notice Called by EigenPodManager when the owner wants to create another ETH validator.
    /// @dev This function only supports staking to a 0x01 validator. For compounding validators, please interact directly with the deposit contract.
    function stake(
        bytes calldata pubkey,
        bytes calldata signature,
        bytes32 depositDataRoot
    ) external payable;

    /// @notice Transfers `amountWei` from this contract to the `recipient`. Only callable by the EigenPodManager as part
    /// of the DelegationManager's withdrawal flow.
    /// @dev `amountWei` is not required to be a whole Gwei amount. Amounts less than a Gwei multiple may be unrecoverable due to Gwei conversion.
    function withdrawRestakedBeaconChainETH(
        address recipient,
        uint256 amount
    ) external;

    /// @dev Create a checkpoint used to prove this pod's active validator set. Checkpoints are completed
    /// by submitting one checkpoint proof per ACTIVE validator. During the checkpoint process, the total
    /// change in ACTIVE validator balance is tracked, and any validators with 0 balance are marked `WITHDRAWN`.
    /// @dev Once finalized, the pod owner is awarded shares corresponding to:
    /// - the total change in their ACTIVE validator balances
    /// - any ETH in the pod not already awarded shares
    /// @dev A checkpoint cannot be created if the pod already has an outstanding checkpoint. If
    /// this is the case, the pod owner MUST complete the existing checkpoint before starting a new one.
    /// @param revertIfNoBalance Forces a revert if the pod ETH balance is 0. This allows the pod owner
    /// to prevent accidentally starting a checkpoint that will not increase their shares
    function startCheckpoint(
        bool revertIfNoBalance
    ) external;

    /// @dev Progress the current checkpoint towards completion by submitting one or more validator
    /// checkpoint proofs. Anyone can call this method to submit proofs towards the current checkpoint.
    /// For each validator proven, the current checkpoint's `proofsRemaining` decreases.
    /// @dev If the checkpoint's `proofsRemaining` reaches 0, the checkpoint is finalized.
    /// (see `_updateCheckpoint` for more details)
    /// @dev This method can only be called when there is a currently-active checkpoint.
    /// @param balanceContainerProof proves the beacon's current balance container root against a checkpoint's `beaconBlockRoot`
    /// @param proofs Proofs for one or more validator current balances against the `balanceContainerRoot`
    function verifyCheckpointProofs(
        BeaconChainProofs.BalanceContainerProof calldata balanceContainerProof,
        BeaconChainProofs.BalanceProof[] calldata proofs
    ) external;

    /// @dev Verify one or more validators have their withdrawal credentials pointed at this EigenPod, and award
    /// shares based on their effective balance. Proven validators are marked `ACTIVE` within the EigenPod, and
    /// future checkpoint proofs will need to include them.
    /// @dev Withdrawal credential proofs MUST NOT be older than `currentCheckpointTimestamp`.
    /// @dev Validators proven via this method MUST NOT have an exit epoch set already.
    /// @param beaconTimestamp the beacon chain timestamp sent to the 4788 oracle contract. Corresponds
    /// to the parent beacon block root against which the proof is verified.
    /// @param stateRootProof proves a beacon state root against a beacon block root
    /// @param validatorIndices a list of validator indices being proven
    /// @param validatorFieldsProofs proofs of each validator's `validatorFields` against the beacon state root
    /// @param validatorFields the fields of the beacon chain "Validator" container. See consensus specs for
    /// details: https://github.com/ethereum/consensus-specs/blob/dev/specs/phase0/beacon-chain.md#validator
    function verifyWithdrawalCredentials(
        uint64 beaconTimestamp,
        BeaconChainProofs.StateRootProof calldata stateRootProof,
        uint40[] calldata validatorIndices,
        bytes[] calldata validatorFieldsProofs,
        bytes32[][] calldata validatorFields
    ) external;

    /// @dev Prove that one of this pod's active validators was slashed on the beacon chain. A successful
    /// staleness proof allows the caller to start a checkpoint.
    ///
    /// @dev Note that in order to start a checkpoint, any existing checkpoint must already be completed!
    /// (See `_startCheckpoint` for details)
    ///
    /// @dev Note that this method allows anyone to start a checkpoint as soon as a slashing occurs on the beacon
    /// chain. This is intended to make it easier to external watchers to keep a pod's balance up to date.
    ///
    /// @dev Note too that beacon chain slashings are not instant. There is a delay between the initial slashing event
    /// and the validator's final exit back to the execution layer. During this time, the validator's balance may or
    /// may not drop further due to a correlation penalty. This method allows proof of a slashed validator
    /// to initiate a checkpoint for as long as the validator remains on the beacon chain. Once the validator
    /// has exited and been checkpointed at 0 balance, they are no longer "checkpoint-able" and cannot be proven
    /// "stale" via this method.
    /// See https://eth2book.info/capella/part3/transition/epoch/#slashings for more info.
    ///
    /// @param beaconTimestamp the beacon chain timestamp sent to the 4788 oracle contract. Corresponds
    /// to the parent beacon block root against which the proof is verified.
    /// @param stateRootProof proves a beacon state root against a beacon block root
    /// @param proof the fields of the beacon chain "Validator" container, along with a merkle proof against
    /// the beacon state root. See the consensus specs for more details:
    /// https://github.com/ethereum/consensus-specs/blob/dev/specs/phase0/beacon-chain.md#validator
    ///
    /// @dev Staleness conditions:
    /// - Validator's last checkpoint is older than `beaconTimestamp`
    /// - Validator MUST be in `ACTIVE` status in the pod
    /// - Validator MUST be slashed on the beacon chain
    function verifyStaleBalance(
        uint64 beaconTimestamp,
        BeaconChainProofs.StateRootProof calldata stateRootProof,
        BeaconChainProofs.ValidatorProof calldata proof
    ) external;

    /// @notice Allows the owner or proof submitter to initiate one or more requests to
    /// consolidate their validators on the beacon chain.
    /// @param requests An array of requests consisting of the source and target pubkeys
    /// of the validators to be consolidated
    /// @dev The target validator MUST have ACTIVE (proven) withdrawal credentials pointed at
    /// the pod. This prevents cross-pod consolidations.
    /// @dev The consolidation request predeploy requires a fee is sent with each request;
    /// this is pulled from msg.value. After submitting all requests, any remaining fee is
    /// refunded to the caller by calling its fallback function.
    /// @dev This contract exposes `getConsolidationRequestFee` to query the current fee for
    /// a single request. If submitting multiple requests in a single block, the total fee
    /// is equal to (fee * requests.length). This fee is updated at the end of each block.
    ///
    /// (See https://eips.ethereum.org/EIPS/eip-7251#fee-calculation for details)
    ///
    /// @dev Note on beacon chain behavior:
    /// - If request.srcPubkey == request.targetPubkey, this is a "switch" consolidation. Once
    ///   processed on the beacon chain, the validator's withdrawal credentials will be changed
    ///   to compounding (0x02).
    /// - The rest of the notes assume src != target.
    /// - The target validator MUST already have 0x02 credentials. The source validator can have either.
    /// - Consolidation sets the source validator's exit_epoch and withdrawable_epoch, similar to an exit.
    ///   When the exit epoch is reached, an epoch sweep will process the consolidation and transfer balance
    ///   from the source to the target validator.
    /// - Consolidation transfers min(srcValidator.effective_balance, state.balance[srcIndex]) to the target.
    ///   This may not be the entirety of the source validator's balance; any remainder will be moved to the
    ///   pod when hit by a subsequent withdrawal sweep.
    ///
    /// @dev Note that consolidation requests CAN FAIL for a variety of reasons. Failures occur when the request
    /// is processed on the beacon chain, and are invisible to the pod. The pod and predeploy cannot guarantee
    /// a request will succeed; it's up to the pod owner to determine this for themselves. If your request fails,
    /// you can retry by initiating another request via this method.
    ///
    /// Some requirements that are NOT checked by the pod:
    /// - If request.srcPubkey == request.targetPubkey, the validator MUST have 0x01 credentials
    /// - If request.srcPubkey != request.targetPubkey, the target validator MUST have 0x02 credentials
    /// - Both the source and target validators MUST be active on the beacon chain and MUST NOT have
    ///   initiated exits
    /// - The source validator MUST NOT have pending partial withdrawal requests (via `requestWithdrawal`)
    /// - If the source validator is slashed after requesting consolidation (but before processing),
    ///   the consolidation will be skipped.
    ///
    /// For further reference, see consolidation processing at block and epoch boundaries:
    /// - Block: https://github.com/ethereum/consensus-specs/blob/dev/specs/electra/beacon-chain.md#new-process_consolidation_request
    /// - Epoch: https://github.com/ethereum/consensus-specs/blob/dev/specs/electra/beacon-chain.md#new-process_pending_consolidations
    function requestConsolidation(
        ConsolidationRequest[] calldata requests
    ) external payable;

    /// @notice Allows the owner or proof submitter to initiate one or more requests to
    /// withdraw funds from validators on the beacon chain.
    /// @param requests An array of requests consisting of the source validator and an
    /// amount to withdraw
    /// @dev The withdrawal request predeploy requires a fee is sent with each request;
    /// this is pulled from msg.value. After submitting all requests, any remaining fee is
    /// refunded to the caller by calling its fallback function.
    /// @dev This contract exposes `getWithdrawalRequestFee` to query the current fee for
    /// a single request. If submitting multiple requests in a single block, the total fee
    /// is equal to (fee * requests.length). This fee is updated at the end of each block.
    ///
    /// (See https://eips.ethereum.org/EIPS/eip-7002#fee-update-rule for details)
    ///
    /// @dev Note on beacon chain behavior:
    /// - Withdrawal requests have two types: full exit requests, and partial exit requests.
    ///   Partial exit requests will be skipped if the validator has 0x01 withdrawal credentials.
    ///   If you want your validators to have access to partial exits, use `requestConsolidation`
    ///   to change their withdrawal credentials to compounding (0x02).
    /// - If request.amount == 0, this is a FULL exit request. A full exit request initiates a
    ///   standard validator exit.
    /// - Other amounts are treated as PARTIAL exit requests. A partial exit request will NOT result
    ///   in a validator with less than 32 ETH balance. Any requested amount above this is ignored.
    /// - The actual amount withdrawn for a partial exit is given by the formula:
    ///   min(request.amount, state.balances[vIdx] - 32 ETH - pending_balance_to_withdraw)
    ///   (where `pending_balance_to_withdraw` is the sum of any outstanding partial exit requests)
    ///   (Note that this means you may request more than is actually withdrawn!)
    ///
    /// @dev Note that withdrawal requests CAN FAIL for a variety of reasons. Failures occur when the request
    /// is processed on the beacon chain, and are invisible to the pod. The pod and predeploy cannot guarantee
    /// a request will succeed; it's up to the pod owner to determine this for themselves. If your request fails,
    /// you can retry by initiating another request via this method.
    ///
    /// Some requirements that are NOT checked by the pod:
    /// - request.pubkey MUST be a valid validator pubkey
    /// - request.pubkey MUST belong to a validator whose withdrawal credentials are this pod
    /// - If request.amount is for a partial exit, the validator MUST have 0x02 withdrawal credentials
    /// - If request.amount is for a full exit, the validator MUST NOT have any pending partial exits
    /// - The validator MUST be active and MUST NOT have initiated exit
    ///
    /// For further reference: https://github.com/ethereum/consensus-specs/blob/dev/specs/electra/beacon-chain.md#new-process_withdrawal_request
    function requestWithdrawal(
        WithdrawalRequest[] calldata requests
    ) external payable;

    /// @notice called by owner of a pod to remove any ERC20s deposited in the pod
    function recoverTokens(
        IERC20[] memory tokenList,
        uint256[] memory amountsToWithdraw,
        address recipient
    ) external;

    /// @notice Allows the owner of a pod to update the proof submitter, a permissioned
    /// address that can call various EigenPod methods, but cannot trigger asset withdrawals
    /// from the DelegationManager.
    /// @dev Note that EITHER the podOwner OR proofSubmitter can access these methods,
    /// so it's fine to set your proofSubmitter to 0 if you want the podOwner to be the
    /// only address that can call these methods.
    /// @param newProofSubmitter The new proof submitter address. If set to 0, only the
    /// pod owner will be able to call EigenPod methods.
    function setProofSubmitter(
        address newProofSubmitter
    ) external;

    ///
    ///                                VIEW METHODS
    ///

    /// @notice An address with permissions to call `startCheckpoint` and `verifyWithdrawalCredentials`, set
    /// by the podOwner. This role exists to allow a podOwner to designate a hot wallet that can call
    /// these methods, allowing the podOwner to remain a cold wallet that is only used to manage funds.
    /// @dev If this address is NOT set, only the podOwner can call `startCheckpoint` and `verifyWithdrawalCredentials`
    function proofSubmitter() external view returns (address);

    /// @notice Native ETH in the pod that has been accounted for in a checkpoint (denominated in gwei).
    /// This amount is withdrawable from the pod via the DelegationManager withdrawal flow.
    function withdrawableRestakedExecutionLayerGwei() external view returns (uint64);

    /// @notice The single EigenPodManager for EigenLayer
    function eigenPodManager() external view returns (IEigenPodManager);

    /// @notice The owner of this EigenPod
    function podOwner() external view returns (address);

    /// @notice Returns the validatorInfo struct for the provided pubkeyHash
    function validatorPubkeyHashToInfo(
        bytes32 validatorPubkeyHash
    ) external view returns (ValidatorInfo memory);

    /// @notice Returns the validatorInfo struct for the provided pubkey
    function validatorPubkeyToInfo(
        bytes calldata validatorPubkey
    ) external view returns (ValidatorInfo memory);

    /// @notice Returns the validator status for a given validator pubkey hash
    function validatorStatus(
        bytes32 pubkeyHash
    ) external view returns (VALIDATOR_STATUS);

    /// @notice Returns the validator status for a given validator pubkey
    function validatorStatus(
        bytes calldata validatorPubkey
    ) external view returns (VALIDATOR_STATUS);

    /// @notice Number of validators with proven withdrawal credentials, who do not have proven full withdrawals
    function activeValidatorCount() external view returns (uint256);

    /// @notice The timestamp of the last checkpoint finalized
    function lastCheckpointTimestamp() external view returns (uint64);

    /// @notice The timestamp of the currently-active checkpoint. Will be 0 if there is not active checkpoint
    function currentCheckpointTimestamp() external view returns (uint64);

    /// @notice Returns the currently-active checkpoint
    /// If there's not an active checkpoint, this method returns the checkpoint that was last active.
    function currentCheckpoint() external view returns (Checkpoint memory);

    /// @notice For each checkpoint, the total balance attributed to exited validators, in gwei
    ///
    /// NOTE that the values added to this mapping are NOT guaranteed to capture the entirety of a validator's
    /// exit - rather, they capture the total change in a validator's balance when a checkpoint shows their
    /// balance change from nonzero to zero. While a change from nonzero to zero DOES guarantee that a validator
    /// has been fully exited, it is possible that the magnitude of this change does not capture what is
    /// typically thought of as a "full exit."
    ///
    /// For example:
    /// 1. Consider a validator was last checkpointed at 32 ETH before exiting. Once the exit has been processed,
    /// it is expected that the validator's exited balance is calculated to be `32 ETH`.
    /// 2. However, before `startCheckpoint` is called, a deposit is made to the validator for 1 ETH. The beacon
    /// chain will automatically withdraw this ETH, but not until the withdrawal sweep passes over the validator
    /// again. Until this occurs, the validator's current balance (used for checkpointing) is 1 ETH.
    /// 3. If `startCheckpoint` is called at this point, the balance delta calculated for this validator will be
    /// `-31 ETH`, and because the validator has a nonzero balance, it is not marked WITHDRAWN.
    /// 4. After the exit is processed by the beacon chain, a subsequent `startCheckpoint` and checkpoint proof
    /// will calculate a balance delta of `-1 ETH` and attribute a 1 ETH exit to the validator.
    ///
    /// If this edge case impacts your usecase, it should be possible to mitigate this by monitoring for deposits
    /// to your exited validators, and waiting to call `startCheckpoint` until those deposits have been automatically
    /// exited.
    ///
    /// Additional edge cases this mapping does not cover:
    /// - If a validator is slashed, their balance exited will reflect their original balance rather than the slashed amount
    /// - The final partial withdrawal for an exited validator will be likely be included in this mapping.
    ///   i.e. if a validator was last checkpointed at 32.1 ETH before exiting, the next checkpoint will calculate their
    ///   "exited" amount to be 32.1 ETH rather than 32 ETH.
    function checkpointBalanceExitedGwei(
        uint64
    ) external view returns (uint64);

    /// @notice Query the 4788 oracle to get the parent block root of the slot with the given `timestamp`
    /// @param timestamp of the block for which the parent block root will be returned. MUST correspond
    /// to an existing slot within the last 24 hours. If the slot at `timestamp` was skipped, this method
    /// will revert.
    function getParentBlockRoot(
        uint64 timestamp
    ) external view returns (bytes32);

    /// @notice Returns the fee required to add a consolidation request to the EIP-7251 predeploy this block.
    /// @dev Note that the predeploy updates its fee every block according to https://eips.ethereum.org/EIPS/eip-7251#fee-calculation
    /// Consider overestimating the amount sent to ensure the fee does not update before your transaction.
    function getConsolidationRequestFee() external view returns (uint256);

    /// @notice Returns the current fee required to add a withdrawal request to the EIP-7002 predeploy.
    /// @dev Note that the predeploy updates its fee every block according to https://eips.ethereum.org/EIPS/eip-7002#fee-update-rule
    /// Consider overestimating the amount sent to ensure the fee does not update before your transaction.
    function getWithdrawalRequestFee() external view returns (uint256);
}

// Source: src/contracts/interfaces/IPausable.sol
/// @title Adds pausability to a contract, with pausing & unpausing controlled by the `pauser` and `unpauser` of a PauserRegistry contract.
/// @author Layr Labs, Inc.
/// @notice Terms of Service: https://docs.eigenlayer.xyz/overview/terms-of-service
/// @notice Contracts that inherit from this contract may define their own `pause` and `unpause` (and/or related) functions.
/// These functions should be permissioned as "onlyPauser" which defers to a `PauserRegistry` for determining access control.
/// @dev Pausability is implemented using a uint256, which allows up to 256 different single bit-flags; each bit can potentially pause different functionality.
/// Inspiration for this was taken from the NearBridge design here https://etherscan.io/address/0x3FEFc5A4B1c02f21cBc8D3613643ba0635b9a873#code.
/// For the `pause` and `unpause` functions we've implemented, if you pause, you can only flip (any number of) switches to on/1 (aka "paused"), and if you unpause,
/// you can only flip (any number of) switches to off/0 (aka "paused").
/// If you want a pauseXYZ function that just flips a single bit / "pausing flag", it will:
/// 1) 'bit-wise and' (aka `&`) a flag with the current paused state (as a uint256)
/// 2) update the paused state to this new value
/// @dev We note as well that we have chosen to identify flags by their *bit index* as opposed to their numerical value, so, e.g. defining `DEPOSITS_PAUSED = 3`
/// indicates specifically that if the *third bit* of `_paused` is flipped -- i.e. it is a '1' -- then deposits should be paused
interface IPausable {
    /// @dev Thrown when caller is not pauser.
    error OnlyPauser();
    /// @dev Thrown when caller is not unpauser.
    error OnlyUnpauser();
    /// @dev Thrown when currently paused.
    error CurrentlyPaused();
    /// @dev Thrown when invalid `newPausedStatus` is provided.
    error InvalidNewPausedStatus();
    /// @dev Thrown when a null address input is provided.
    error InputAddressZero();

    /// @notice Emitted when the pause is triggered by `account`, and changed to `newPausedStatus`.
    event Paused(address indexed account, uint256 newPausedStatus);

    /// @notice Emitted when the pause is lifted by `account`, and changed to `newPausedStatus`.
    event Unpaused(address indexed account, uint256 newPausedStatus);

    /// @notice Address of the `PauserRegistry` contract that this contract defers to for determining access control (for pausing).
    function pauserRegistry() external view returns (IPauserRegistry);

    /// @notice This function is used to pause an EigenLayer contract's functionality.
    /// It is permissioned to the `pauser` address, which is expected to be a low threshold multisig.
    /// @param newPausedStatus represents the new value for `_paused` to take, which means it may flip several bits at once.
    /// @dev This function can only pause functionality, and thus cannot 'unflip' any bit in `_paused` from 1 to 0.
    function pause(
        uint256 newPausedStatus
    ) external;

    /// @notice Alias for `pause(type(uint256).max)`.
    function pauseAll() external;

    /// @notice This function is used to unpause an EigenLayer contract's functionality.
    /// It is permissioned to the `unpauser` address, which is expected to be a high threshold multisig or governance contract.
    /// @param newPausedStatus represents the new value for `_paused` to take, which means it may flip several bits at once.
    /// @dev This function can only unpause functionality, and thus cannot 'flip' any bit in `_paused` from 0 to 1.
    function unpause(
        uint256 newPausedStatus
    ) external;

    /// @notice Returns the current paused status as a uint256.
    function paused() external view returns (uint256);

    /// @notice Returns 'true' if the `indexed`th bit of `_paused` is 1, and 'false' otherwise
    function paused(
        uint8 index
    ) external view returns (bool);
}

// Source: src/contracts/interfaces/IEigenPodManager.sol
interface IEigenPodManagerErrors {
    /// @dev Thrown when caller is not a EigenPod.
    error OnlyEigenPod();
    /// @dev Thrown when caller is not DelegationManager.
    error OnlyDelegationManager();
    /// @dev Thrown when caller already has an EigenPod.
    error EigenPodAlreadyExists();
    /// @dev Thrown when shares is not a multiple of gwei.
    error SharesNotMultipleOfGwei();
    /// @dev Thrown when shares would result in a negative integer.
    error SharesNegative();
    /// @dev Thrown when the strategy is not the beaconChainETH strategy.
    error InvalidStrategy();
    /// @dev Thrown when the pods shares are negative and a beacon chain balance update is attempted.
    /// The podOwner should complete legacy withdrawal first.
    error LegacyWithdrawalsNotCompleted();
    /// @dev Thrown when caller is not the proof timestamp setter
    error OnlyProofTimestampSetter();
}

interface IEigenPodManagerEvents {
    /// @notice Emitted to notify the deployment of an EigenPod
    event PodDeployed(address indexed eigenPod, address indexed podOwner);

    /// @notice Emitted to notify a deposit of beacon chain ETH recorded in the strategy manager
    event BeaconChainETHDeposited(address indexed podOwner, uint256 amount);

    /// @notice Emitted when the balance of an EigenPod is updated
    event PodSharesUpdated(address indexed podOwner, int256 sharesDelta);

    /// @notice Emitted every time the total shares of a pod are updated
    event NewTotalShares(address indexed podOwner, int256 newTotalShares);

    /// @notice Emitted when a withdrawal of beacon chain ETH is completed
    event BeaconChainETHWithdrawalCompleted(
        address indexed podOwner,
        uint256 shares,
        uint96 nonce,
        address delegatedAddress,
        address withdrawer,
        bytes32 withdrawalRoot
    );

    /// @notice Emitted when a staker's beaconChainSlashingFactor is updated
    event BeaconChainSlashingFactorDecreased(
        address staker,
        uint64 prevBeaconChainSlashingFactor,
        uint64 newBeaconChainSlashingFactor
    );

    /// @notice Emitted when an operator is slashed and shares to be burned are increased
    event BurnableETHSharesIncreased(uint256 shares);

    /// @notice Emitted when the Pectra fork timestamp is updated
    event PectraForkTimestampSet(uint64 newPectraForkTimestamp);

    /// @notice Emitted when the proof timestamp setter is updated
    event ProofTimestampSetterSet(address newProofTimestampSetter);
}

interface IEigenPodManagerTypes {
    /// @notice The amount of beacon chain slashing experienced by a pod owner as a proportion of WAD
    /// @param isSet whether the slashingFactor has ever been updated. Used to distinguish between
    /// a value of "0" and an uninitialized value.
    /// @param slashingFactor the proportion of the pod owner's balance that has been decreased due to
    /// slashing or other beacon chain balance decreases.
    /// @dev NOTE: if !isSet, `slashingFactor` should be treated as WAD. `slashingFactor` is monotonically
    /// decreasing and can hit 0 if fully slashed.
    struct BeaconChainSlashingFactor {
        bool isSet;
        uint64 slashingFactor;
    }
}

/// @title Interface for factory that creates and manages solo staking pods that have their withdrawal credentials pointed to EigenLayer.
/// @author Layr Labs, Inc.
/// @notice Terms of Service: https://docs.eigenlayer.xyz/overview/terms-of-service
interface IEigenPodManager is
    IEigenPodManagerErrors,
    IEigenPodManagerEvents,
    IEigenPodManagerTypes,
    IShareManager,
    IPausable
{
    /// @notice Creates an EigenPod for the sender.
    /// @dev Function will revert if the `msg.sender` already has an EigenPod.
    /// @dev Returns EigenPod address
    function createPod() external returns (address);

    /// @notice Stakes for a new beacon chain validator on the sender's EigenPod.
    /// Also creates an EigenPod for the sender if they don't have one already.
    /// @param pubkey The 48 bytes public key of the beacon chain validator.
    /// @param signature The validator's signature of the deposit data.
    /// @param depositDataRoot The root/hash of the deposit data for the validator's deposit.
    function stake(
        bytes calldata pubkey,
        bytes calldata signature,
        bytes32 depositDataRoot
    ) external payable;

    /// @notice Adds any positive share delta to the pod owner's deposit shares, and delegates them to the pod
    /// owner's operator (if applicable). A negative share delta does NOT impact the pod owner's deposit shares,
    /// but will reduce their beacon chain slashing factor and delegated shares accordingly.
    /// @param podOwner is the pod owner whose balance is being updated.
    /// @param prevRestakedBalanceWei is the total amount restaked through the pod before the balance update, including
    /// any amount currently in the withdrawal queue.
    /// @param balanceDeltaWei is the amount the balance changed
    /// @dev Callable only by the podOwner's EigenPod contract.
    /// @dev Reverts if `sharesDelta` is not a whole Gwei amount
    function recordBeaconChainETHBalanceUpdate(
        address podOwner,
        uint256 prevRestakedBalanceWei,
        int256 balanceDeltaWei
    ) external;

    /// @notice Sets the address that can set proof timestamps
    function setProofTimestampSetter(
        address newProofTimestampSetter
    ) external;

    /// @notice Sets the Pectra fork timestamp, only callable by `proofTimestampSetter`
    function setPectraForkTimestamp(
        uint64 timestamp
    ) external;

    /// @notice Returns the address of the `podOwner`'s EigenPod if it has been deployed.
    function ownerToPod(
        address podOwner
    ) external view returns (IEigenPod);

    /// @notice Returns the address of the `podOwner`'s EigenPod (whether it is deployed yet or not).
    function getPod(
        address podOwner
    ) external view returns (IEigenPod);

    /// @notice The ETH2 Deposit Contract
    function ethPOS() external view returns (IETHPOSDeposit);

    /// @notice Beacon proxy to which the EigenPods point
    function eigenPodBeacon() external view returns (IBeacon);

    /// @notice Returns 'true' if the `podOwner` has created an EigenPod, and 'false' otherwise.
    function hasPod(
        address podOwner
    ) external view returns (bool);

    /// @notice Returns the number of EigenPods that have been created
    function numPods() external view returns (uint256);

    /// @notice Mapping from Pod owner owner to the number of shares they have in the virtual beacon chain ETH strategy.
    /// @dev The share amount can become negative. This is necessary to accommodate the fact that a pod owner's virtual beacon chain ETH shares can
    /// decrease between the pod owner queuing and completing a withdrawal.
    /// When the pod owner's shares would otherwise increase, this "deficit" is decreased first _instead_.
    /// Likewise, when a withdrawal is completed, this "deficit" is decreased and the withdrawal amount is decreased; We can think of this
    /// as the withdrawal "paying off the deficit".
    function podOwnerDepositShares(
        address podOwner
    ) external view returns (int256);

    /// @notice returns canonical, virtual beaconChainETH strategy
    function beaconChainETHStrategy() external view returns (IStrategy);

    /// @notice Returns the historical sum of proportional balance decreases a pod owner has experienced when
    /// updating their pod's balance.
    function beaconChainSlashingFactor(
        address staker
    ) external view returns (uint64);

    /// @notice Returns the accumulated amount of beacon chain ETH Strategy shares
    function burnableETHShares() external view returns (uint256);

    /// @notice Returns the timestamp of the Pectra hard fork
    /// @dev Specifically, this returns the timestamp of the first non-missed slot at or after the Pectra hard fork
    function pectraForkTimestamp() external view returns (uint64);
}

// Source: src/contracts/permissions/Pausable.sol
/// @title Adds pausability to a contract, with pausing & unpausing controlled by the `pauser` and `unpauser` of a PauserRegistry contract.
/// @author Layr Labs, Inc.
/// @notice Terms of Service: https://docs.eigenlayer.xyz/overview/terms-of-service
/// @notice Contracts that inherit from this contract may define their own `pause` and `unpause` (and/or related) functions.
/// These functions should be permissioned as "onlyPauser" which defers to a `PauserRegistry` for determining access control.
/// @dev Pausability is implemented using a uint256, which allows up to 256 different single bit-flags; each bit can potentially pause different functionality.
/// Inspiration for this was taken from the NearBridge design here https://etherscan.io/address/0x3FEFc5A4B1c02f21cBc8D3613643ba0635b9a873#code.
/// For the `pause` and `unpause` functions we've implemented, if you pause, you can only flip (any number of) switches to on/1 (aka "paused"), and if you unpause,
/// you can only flip (any number of) switches to off/0 (aka "paused").
/// If you want a pauseXYZ function that just flips a single bit / "pausing flag", it will:
/// 1) 'bit-wise and' (aka `&`) a flag with the current paused state (as a uint256)
/// 2) update the paused state to this new value
/// @dev We note as well that we have chosen to identify flags by their *bit index* as opposed to their numerical value, so, e.g. defining `DEPOSITS_PAUSED = 3`
/// indicates specifically that if the *third bit* of `_paused` is flipped -- i.e. it is a '1' -- then deposits should be paused
abstract contract Pausable is IPausable {
    /// Constants
    uint256 internal constant _UNPAUSE_ALL = 0;

    uint256 internal constant _PAUSE_ALL = type(uint256).max;

    /// @notice Address of the `PauserRegistry` contract that this contract defers to for determining access control (for pausing).
    IPauserRegistry public immutable pauserRegistry;

    /// Storage

    /// @dev Do not remove, deprecated storage.
    IPauserRegistry private __deprecated_pauserRegistry;

    /// @dev Returns a bitmap representing the paused status of the contract.
    uint256 private _paused;

    /// Modifiers

    /// @dev Thrown if the caller is not a valid pauser according to the pauser registry.
    modifier onlyPauser() {
        _checkOnlyPauser();
        _;
    }

    /// @dev Thrown if the caller is not a valid unpauser according to the pauser registry.
    modifier onlyUnpauser() {
        _checkOnlyUnpauser();
        _;
    }

    /// @dev Thrown if the contract is paused, i.e. if any of the bits in `_paused` is flipped to 1.
    modifier whenNotPaused() {
        _checkOnlyWhenNotPaused();
        _;
    }

    /// @dev Thrown if the `indexed`th bit of `_paused` is 1, i.e. if the `index`th pause switch is flipped.
    modifier onlyWhenNotPaused(
        uint8 index
    ) {
        _checkOnlyWhenNotPaused(index);
        _;
    }

    function _checkOnlyPauser() internal view {
        require(pauserRegistry.isPauser(msg.sender), OnlyPauser());
    }

    function _checkOnlyUnpauser() internal view {
        require(msg.sender == pauserRegistry.unpauser(), OnlyUnpauser());
    }

    function _checkOnlyWhenNotPaused() internal view {
        require(_paused == 0, CurrentlyPaused());
    }

    function _checkOnlyWhenNotPaused(
        uint8 index
    ) internal view {
        require(!paused(index), CurrentlyPaused());
    }

    /// Construction

    constructor(
        IPauserRegistry _pauserRegistry
    ) {
        require(address(_pauserRegistry) != address(0), InputAddressZero());
        pauserRegistry = _pauserRegistry;
    }

    /// @inheritdoc IPausable
    function pause(
        uint256 newPausedStatus
    ) external onlyPauser {
        uint256 currentPausedStatus = _paused;
        // verify that the `newPausedStatus` does not *unflip* any bits (i.e. doesn't unpause anything, all 1 bits remain)
        require((currentPausedStatus & newPausedStatus) == currentPausedStatus, InvalidNewPausedStatus());
        _setPausedStatus(newPausedStatus);
    }

    /// @inheritdoc IPausable
    function pauseAll() external onlyPauser {
        _setPausedStatus(_PAUSE_ALL);
    }

    /// @inheritdoc IPausable
    function unpause(
        uint256 newPausedStatus
    ) external onlyUnpauser {
        uint256 currentPausedStatus = _paused;
        // verify that the `newPausedStatus` does not *flip* any bits (i.e. doesn't pause anything, all 0 bits remain)
        require(((~currentPausedStatus) & (~newPausedStatus)) == (~currentPausedStatus), InvalidNewPausedStatus());
        _paused = newPausedStatus;
        emit Unpaused(msg.sender, newPausedStatus);
    }

    /// @inheritdoc IPausable
    function paused() public view virtual returns (uint256) {
        return _paused;
    }

    /// @inheritdoc IPausable
    function paused(
        uint8 index
    ) public view virtual returns (bool) {
        uint256 mask = 1 << index;
        return ((_paused & mask) == mask);
    }

    /// @dev Internal helper for setting the paused status, and emitting the corresponding event.
    function _setPausedStatus(
        uint256 pausedStatus
    ) internal {
        _paused = pausedStatus;
        emit Paused(msg.sender, pausedStatus);
    }

    /// @dev This empty reserved space is put in place to allow future versions to add new
    /// variables without shifting down storage in the inheritance chain.
    /// See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[48] private __gap;
}

// Source: lib/openzeppelin-contracts-v4.9.0/contracts/utils/structs/EnumerableSet.sol
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// Source: lib/openzeppelin-contracts-v4.9.0/contracts/utils/structs/EnumerableMap.sol
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableMap.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableMap.js.




/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32Map`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableMap.
 * ====
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(Bytes32ToBytes32Map storage map, bytes32 key, bytes32 value) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(Bytes32ToBytes32Map storage map) internal view returns (bytes32[] memory) {
        return map._keys.values();
    }

    // UintToUintMap

    struct UintToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToUintMap storage map, uint256 key, uint256 value) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToUintMap storage map, uint256 key, string memory errorMessage) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key), errorMessage));
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(UintToUintMap storage map) internal view returns (uint256[] memory) {
        bytes32[] memory store = keys(map._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(UintToAddressMap storage map) internal view returns (uint256[] memory) {
        bytes32[] memory store = keys(map._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(AddressToUintMap storage map, address key, uint256 value) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(AddressToUintMap storage map) internal view returns (address[] memory) {
        bytes32[] memory store = keys(map._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(Bytes32ToUintMap storage map, bytes32 key, uint256 value) internal returns (bool) {
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, key, errorMessage));
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(Bytes32ToUintMap storage map) internal view returns (bytes32[] memory) {
        bytes32[] memory store = keys(map._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// Source: src/contracts/interfaces/IAVSRegistrar.sol
interface IAVSRegistrar {
    /// @notice Called by the AllocationManager when an operator wants to register
    /// for one or more operator sets. This method should revert if registration
    /// is unsuccessful.
    /// @param operator the registering operator
    /// @param avs the AVS the operator is registering for. This should be the same as IAVSRegistrar.avs()
    /// @param operatorSetIds the list of operator set ids being registered for
    /// @param data arbitrary data the operator can provide as part of registration
    function registerOperator(
        address operator,
        address avs,
        uint32[] calldata operatorSetIds,
        bytes calldata data
    ) external;

    /// @notice Called by the AllocationManager when an operator is deregistered from one or more operator sets
    /// @param operator the deregistering operator
    /// @param avs the AVS the operator is deregistering from. This should be the same as IAVSRegistrar.avs()
    /// @param operatorSetIds the list of operator set ids being deregistered from
    function deregisterOperator(
        address operator,
        address avs,
        uint32[] calldata operatorSetIds
    ) external;

    /// @notice Returns true if the AVS is supported by the registrar
    /// @param avs the AVS to check
    /// @return true if the AVS is supported, false otherwise
    function supportsAVS(
        address avs
    ) external view returns (bool);
}

// Source: src/contracts/interfaces/IAllocationManager.sol
interface IAllocationManagerErrors {
    /// Input Validation
    /// @dev Thrown when `wadToSlash` is zero or greater than 1e18
    error InvalidWadToSlash();
    /// @dev Thrown when two array parameters have mismatching lengths.
    error InputArrayLengthMismatch();
    /// @dev Thrown when the AVSRegistrar is not correctly configured to prevent an AVSRegistrar contract
    /// from being used with the wrong AVS
    error InvalidAVSRegistrar();
    /// @dev Thrown when an invalid strategy is provided.
    error InvalidStrategy();
    /// @dev Thrown when an invalid redistribution recipient is provided.
    error InvalidRedistributionRecipient();
    /// @dev Thrown when an operatorSet is already migrated
    error OperatorSetAlreadyMigrated();

    /// Caller

    /// @dev Thrown when caller is not authorized to call a function.
    error InvalidCaller();

    /// Operator Status

    /// @dev Thrown when an invalid operator is provided.
    error InvalidOperator();
    /// @dev Thrown when an invalid avs whose metadata is not registered is provided.
    error NonexistentAVSMetadata();
    /// @dev Thrown when an operator's allocation delay has yet to be set.
    error UninitializedAllocationDelay();
    /// @dev Thrown when attempting to slash an operator when they are not slashable.
    error OperatorNotSlashable();
    /// @dev Thrown when trying to add an operator to a set they are already a member of
    error AlreadyMemberOfSet();
    /// @dev Thrown when trying to slash/remove an operator from a set they are not a member of
    error NotMemberOfSet();

    /// Operator Set Status

    /// @dev Thrown when an invalid operator set is provided.
    error InvalidOperatorSet();
    /// @dev Thrown when provided `strategies` are not in ascending order.
    error StrategiesMustBeInAscendingOrder();
    /// @dev Thrown when trying to add a strategy to an operator set that already contains it.
    error StrategyAlreadyInOperatorSet();
    /// @dev Thrown when a strategy is referenced that does not belong to an operator set.
    error StrategyNotInOperatorSet();

    /// Modifying Allocations

    /// @dev Thrown when an operator attempts to set their allocation for an operatorSet to the same value
    error SameMagnitude();
    /// @dev Thrown when an allocation is attempted for a given operator when they have pending allocations or deallocations.
    error ModificationAlreadyPending();
    /// @dev Thrown when an allocation is attempted that exceeds a given operators total allocatable magnitude.
    error InsufficientMagnitude();

    /// SlasherStatus

    /// @dev Thrown when an operator set does not have a slasher set
    error SlasherNotSet();
}

interface IAllocationManagerTypes {
    /// @notice Defines allocation information from a strategy to an operator set, for an operator
    /// @param currentMagnitude the current magnitude allocated from the strategy to the operator set
    /// @param pendingDiff a pending change in magnitude, if it exists (0 otherwise)
    /// @param effectBlock the block at which the pending magnitude diff will take effect
    struct Allocation {
        uint64 currentMagnitude;
        int128 pendingDiff;
        uint32 effectBlock;
    }

    /// @notice Slasher configuration for an operator set.
    /// @param slasher The current effective slasher address. Updated immediately when instantEffectBlock=true
    ///        (e.g., during operator set creation or migration).
    /// @param pendingSlasher The slasher address that will become effective at effectBlock.
    /// @param effectBlock The block number at which pendingSlasher becomes the effective slasher.
    /// @dev It is not possible for the slasher to be the 0 address, which is used to denote if the slasher is not set
    struct SlasherParams {
        address slasher;
        address pendingSlasher;
        uint32 effectBlock;
    }

    /// @notice Allocation delay configuration for an operator.
    /// @param delay The current effective allocation delay. Updated immediately for newly registered operators.
    /// @param isSet Whether the allocation delay has been configured. True immediately for newly registered operators.
    /// @param pendingDelay The allocation delay that will become effective at effectBlock.
    /// @param effectBlock The block number at which pendingDelay becomes the effective delay.
    struct AllocationDelayInfo {
        uint32 delay;
        bool isSet;
        uint32 pendingDelay;
        uint32 effectBlock;
    }

    /// @notice Contains registration details for an operator pertaining to an operator set
    /// @param registered Whether the operator is currently registered for the operator set
    /// @param slashableUntil If the operator is not registered, they are still slashable until
    /// this block is reached.
    struct RegistrationStatus {
        bool registered;
        uint32 slashableUntil;
    }

    /// @notice Contains allocation info for a specific strategy
    /// @param maxMagnitude the maximum magnitude that can be allocated between all operator sets
    /// @param encumberedMagnitude the currently-allocated magnitude for the strategy
    struct StrategyInfo {
        uint64 maxMagnitude;
        uint64 encumberedMagnitude;
    }

    /// @notice Struct containing parameters to slashing
    /// @param operator the address to slash
    /// @param operatorSetId the ID of the operatorSet the operator is being slashed on behalf of
    /// @param strategies the set of strategies to slash
    /// @param wadsToSlash the parts in 1e18 to slash, this will be proportional to the operator's
    /// slashable stake allocation for the operatorSet
    /// @param description the description of the slashing provided by the AVS for legibility
    struct SlashingParams {
        address operator;
        uint32 operatorSetId;
        IStrategy[] strategies;
        uint256[] wadsToSlash;
        string description;
    }

    /// @notice struct used to modify the allocation of slashable magnitude to an operator set
    /// @param operatorSet the operator set to modify the allocation for
    /// @param strategies the strategies to modify allocations for
    /// @param newMagnitudes the new magnitude to allocate for each strategy to this operator set
    struct AllocateParams {
        OperatorSet operatorSet;
        IStrategy[] strategies;
        uint64[] newMagnitudes;
    }

    /// @notice Parameters used to register for an AVS's operator sets
    /// @param avs the AVS being registered for
    /// @param operatorSetIds the operator sets within the AVS to register for
    /// @param data extra data to be passed to the AVS to complete registration
    struct RegisterParams {
        address avs;
        uint32[] operatorSetIds;
        bytes data;
    }

    /// @notice Parameters used to deregister from an AVS's operator sets
    /// @param operator the operator being deregistered
    /// @param avs the avs being deregistered from
    /// @param operatorSetIds the operator sets within the AVS being deregistered from
    struct DeregisterParams {
        address operator;
        address avs;
        uint32[] operatorSetIds;
    }

    /// @notice Parameters used by an AVS to create new operator sets
    /// @param operatorSetId the id of the operator set to create
    /// @param strategies the strategies to add as slashable to the operator set
    /// @dev This struct and its associated method will be deprecated in Early Q2 2026
    struct CreateSetParams {
        uint32 operatorSetId;
        IStrategy[] strategies;
    }
    /// @notice Parameters used by an AVS to create new operator sets
    /// @param operatorSetId the id of the operator set to create
    /// @param strategies the strategies to add as slashable to the operator set
    /// @param slasher the address that will be the slasher for the operator set

    struct CreateSetParamsV2 {
        uint32 operatorSetId;
        IStrategy[] strategies;
        address slasher;
    }
}

interface IAllocationManagerEvents is IAllocationManagerTypes {
    /// @notice Emitted when operator updates their allocation delay.
    event AllocationDelaySet(address operator, uint32 delay, uint32 effectBlock);

    /// @notice Emitted when an operator set's slasher is updated.
    event SlasherUpdated(OperatorSet operatorSet, address slasher, uint32 effectBlock);

    /// @notice Emitted when an operator set's slasher is migrated.
    event SlasherMigrated(OperatorSet operatorSet, address slasher);

    /// @notice Emitted when an operator's magnitude is updated for a given operatorSet and strategy
    event AllocationUpdated(
        address operator,
        OperatorSet operatorSet,
        IStrategy strategy,
        uint64 magnitude,
        uint32 effectBlock
    );

    /// @notice Emitted when operator's encumbered magnitude is updated for a given strategy
    event EncumberedMagnitudeUpdated(address operator, IStrategy strategy, uint64 encumberedMagnitude);

    /// @notice Emitted when an operator's max magnitude is updated for a given strategy
    event MaxMagnitudeUpdated(address operator, IStrategy strategy, uint64 maxMagnitude);

    /// @notice Emitted when an operator is slashed by an operator set for a strategy
    /// `wadSlashed` is the proportion of the operator's total delegated stake that was slashed
    event OperatorSlashed(
        address operator,
        OperatorSet operatorSet,
        IStrategy[] strategies,
        uint256[] wadSlashed,
        string description
    );

    /// @notice Emitted when an AVS configures the address that will handle registration/deregistration
    event AVSRegistrarSet(address avs, IAVSRegistrar registrar);

    /// @notice Emitted when an AVS updates their metadata URI (Uniform Resource Identifier).
    /// @dev The URI is never stored; it is simply emitted through an event for off-chain indexing.
    event AVSMetadataURIUpdated(address indexed avs, string metadataURI);

    /// @notice Emitted when an operator set is created by an AVS.
    event OperatorSetCreated(OperatorSet operatorSet);

    /// @notice Emitted when an operator is added to an operator set.
    event OperatorAddedToOperatorSet(address indexed operator, OperatorSet operatorSet);

    /// @notice Emitted when an operator is removed from an operator set.
    event OperatorRemovedFromOperatorSet(address indexed operator, OperatorSet operatorSet);

    /// @notice Emitted when a redistributing operator set is created by an AVS.
    event RedistributionAddressSet(OperatorSet operatorSet, address redistributionRecipient);

    /// @notice Emitted when a strategy is added to an operator set.
    event StrategyAddedToOperatorSet(OperatorSet operatorSet, IStrategy strategy);

    /// @notice Emitted when a strategy is removed from an operator set.
    event StrategyRemovedFromOperatorSet(OperatorSet operatorSet, IStrategy strategy);
}

interface IAllocationManagerStorage is IAllocationManagerEvents {
    /// @notice The DelegationManager contract for EigenLayer
    function delegation() external view returns (IDelegationManager);

    /// @notice The Eigen strategy contract
    /// @dev Cannot be added to redistributing operator sets
    function eigenStrategy() external view returns (IStrategy);

    /// @notice Returns the number of blocks between an operator deallocating magnitude and the magnitude becoming
    /// unslashable and then being able to be reallocated to another operator set. Note that unlike the allocation delay
    /// which is configurable by the operator, the DEALLOCATION_DELAY is globally fixed and cannot be changed.
    function DEALLOCATION_DELAY() external view returns (uint32 delay);

    /// @notice Delay before alloaction delay modifications take effect.
    function ALLOCATION_CONFIGURATION_DELAY() external view returns (uint32);

    /// @notice Delay before slasher changes take effect.
    /// @dev Currently set to the same value as ALLOCATION_CONFIGURATION_DELAY.
    function SLASHER_CONFIGURATION_DELAY() external view returns (uint32);
}

interface IAllocationManagerActions is IAllocationManagerErrors, IAllocationManagerEvents, IAllocationManagerStorage {
    /// @dev Initializes the initial owner and paused status.
    function initialize(
        uint256 initialPausedStatus
    ) external;

    /// @notice Called by an AVS to slash an operator in a given operator set. The operator must be registered
    /// and have slashable stake allocated to the operator set.
    ///
    /// @param avs The AVS address initiating the slash.
    /// @param params The slashing parameters, containing:
    ///  - operator: The operator to slash.
    ///  - operatorSetId: The ID of the operator set the operator is being slashed from.
    ///  - strategies: Array of strategies to slash allocations from (must be in ascending order).
    ///  - wadsToSlash: Array of proportions to slash from each strategy (must be between 0 and 1e18).
    ///  - description: Description of why the operator was slashed.
    ///
    /// @return slashId The ID of the slash.
    /// @return shares The amount of shares that were slashed for each strategy.
    ///
    /// @dev For each strategy:
    ///      1. Reduces the operator's current allocation magnitude by wadToSlash proportion.
    ///      2. Reduces the strategy's max and encumbered magnitudes proportionally.
    ///      3. If there is a pending deallocation, reduces it proportionally.
    ///      4. Updates the operator's shares in the DelegationManager.
    ///
    /// @dev Small slashing amounts may not result in actual token burns due to
    ///      rounding, which will result in small amounts of tokens locked in the contract
    ///      rather than fully burning through the burn mechanism.
    function slashOperator(
        address avs,
        SlashingParams calldata params
    ) external returns (uint256 slashId, uint256[] memory shares);

    /// @notice Modifies the proportions of slashable stake allocated to an operator set from a list of strategies
    /// Note that deallocations remain slashable for DEALLOCATION_DELAY blocks therefore when they are cleared they may
    /// free up less allocatable magnitude than initially deallocated.
    /// @param operator the operator to modify allocations for
    /// @param params array of magnitude adjustments for one or more operator sets
    /// @dev Updates encumberedMagnitude for the updated strategies
    function modifyAllocations(
        address operator,
        AllocateParams[] calldata params
    ) external;

    /// @notice This function takes a list of strategies and for each strategy, removes from the deallocationQueue
    /// all clearable deallocations up to max `numToClear` number of deallocations, updating the encumberedMagnitude
    /// of the operator as needed.
    ///
    /// @param operator address to clear deallocations for
    /// @param strategies a list of strategies to clear deallocations for
    /// @param numToClear a list of number of pending deallocations to clear for each strategy
    ///
    /// @dev can be called permissionlessly by anyone
    function clearDeallocationQueue(
        address operator,
        IStrategy[] calldata strategies,
        uint16[] calldata numToClear
    ) external;

    /// @notice Allows an operator to register for one or more operator sets for an AVS. If the operator
    /// has any stake allocated to these operator sets, it immediately becomes slashable.
    /// @dev After registering within the ALM, this method calls the AVS Registrar's `IAVSRegistrar.
    /// registerOperator` method to complete registration. This call MUST succeed in order for
    /// registration to be successful.
    function registerForOperatorSets(
        address operator,
        RegisterParams calldata params
    ) external;

    /// @notice Allows an operator or AVS to deregister the operator from one or more of the AVS's operator sets.
    /// If the operator has any slashable stake allocated to the AVS, it remains slashable until the
    /// DEALLOCATION_DELAY has passed.
    /// @dev After deregistering within the ALM, this method calls the AVS Registrar's `IAVSRegistrar.
    /// deregisterOperator` method to complete deregistration. This call MUST succeed in order for
    /// deregistration to be successful.
    function deregisterFromOperatorSets(
        DeregisterParams calldata params
    ) external;

    /// @notice Called by the delegation manager OR an operator to set an operator's allocation delay.
    /// This is set when the operator first registers, and is the number of blocks between an operator
    /// allocating magnitude to an operator set, and the magnitude becoming slashable.
    /// @param operator The operator to set the delay on behalf of.
    /// @param delay the allocation delay in blocks
    /// @dev When the delay is set for a newly-registered operator (via the `DelegationManager.registerAsOperator` method),
    /// the delay will take effect immediately, allowing for operators to allocate slashable stake immediately.
    /// Else, the delay will take effect after `ALLOCATION_CONFIGURATION_DELAY` blocks.
    function setAllocationDelay(
        address operator,
        uint32 delay
    ) external;

    /// @notice Called by an AVS to configure the address that is called when an operator registers
    /// or is deregistered from the AVS's operator sets. If not set (or set to 0), defaults
    /// to the AVS's address.
    /// @param registrar the new registrar address
    function setAVSRegistrar(
        address avs,
        IAVSRegistrar registrar
    ) external;

    ///  @notice Called by an AVS to emit an `AVSMetadataURIUpdated` event indicating the information has updated.
    ///
    ///  @param metadataURI The URI for metadata associated with an AVS.
    ///
    ///  @dev Note that the `metadataURI` is *never stored* and is only emitted in the `AVSMetadataURIUpdated` event.
    function updateAVSMetadataURI(
        address avs,
        string calldata metadataURI
    ) external;

    /// @notice Allows an AVS to create new operator sets, defining strategies that the operator set uses
    /// @dev Upon creation, the address that can slash the operatorSet is the `avs` address. If you would like to use a different address,
    ///      use the `createOperatorSets` method which takes in `CreateSetParamsV2` instead.
    /// @dev THIS FUNCTION WILL BE DEPRECATED IN EARLY Q2 2026 IN FAVOR OF `createOperatorSets`, WHICH TAKES IN `CreateSetParamsV2`
    /// @dev Reverts for:
    ///      - NonexistentAVSMetadata: The AVS metadata is not registered
    ///      - InvalidOperatorSet: The operatorSet already exists
    ///      - InputAddressZero: The slasher is the zero address
    function createOperatorSets(
        address avs,
        CreateSetParams[] calldata params
    ) external;

    /// @notice Allows an AVS to create new operator sets, defining strategies that the operator set uses
    /// @dev Reverts for:
    ///      - NonexistentAVSMetadata: The AVS metadata is not registered
    ///      - InvalidOperatorSet: The operatorSet already exists
    ///      - InputAddressZero: The slasher is the zero address
    function createOperatorSets(
        address avs,
        CreateSetParamsV2[] calldata params
    ) external;

    /// @notice Allows an AVS to create new Redistribution operator sets.
    /// @param avs The AVS creating the new operator sets.
    /// @param params An array of operator set creation parameters.
    /// @param redistributionRecipients An array of addresses that will receive redistributed funds when operators are slashed.
    /// @dev Same logic as `createOperatorSets`, except `redistributionRecipients` corresponding to each operator set are stored.
    ///      Additionally, emits `RedistributionOperatorSetCreated` event instead of `OperatorSetCreated` for each created operator set.
    /// @dev The address that can slash the operatorSet is the `avs` address. If you would like to use a different address,
    ///      use the `createOperatorSets` method which takes in `CreateSetParamsV2` instead.
    /// @dev THIS FUNCTION WILL BE DEPRECATED IN EARLY Q2 2026 IN FAVOR OF `createRedistributingOperatorSets` WHICH TAKES IN `CreateSetParamsV2`
    /// @dev Reverts for:
    ///      - InputArrayLengthMismatch: The length of the params array does not match the length of the redistributionRecipients array
    ///      - NonexistentAVSMetadata: The AVS metadata is not registered
    ///      - InputAddressZero: The redistribution recipient is the zero address
    ///      - InvalidRedistributionRecipient: The redistribution recipient is the zero address or the default burn address
    ///      - InvalidOperatorSet: The operatorSet already exists
    ///      - InvalidStrategy: The strategy is the BEACONCHAIN_ETH_STRAT or the EIGEN strategy
    ///      - InputAddressZero: The slasher is the zero address
    function createRedistributingOperatorSets(
        address avs,
        CreateSetParams[] calldata params,
        address[] calldata redistributionRecipients
    ) external;

    /// @notice Allows an AVS to create new Redistribution operator sets.
    /// @param avs The AVS creating the new operator sets.
    /// @param params An array of operator set creation parameters.
    /// @param redistributionRecipients An array of addresses that will receive redistributed funds when operators are slashed.
    /// @dev Same logic as `createOperatorSets`, except `redistributionRecipients` corresponding to each operator set are stored.
    ///      Additionally, emits `RedistributionOperatorSetCreated` event instead of `OperatorSetCreated` for each created operator set.
    /// @dev Reverts for:
    ///      - InputArrayLengthMismatch: The length of the params array does not match the length of the redistributionRecipients array
    ///      - NonexistentAVSMetadata: The AVS metadata is not registered
    ///      - InputAddressZero: The redistribution recipient is the zero address
    ///      - InvalidRedistributionRecipient: The redistribution recipient is the zero address or the default burn address
    ///      - InvalidOperatorSet: The operatorSet already exists
    ///      - InvalidStrategy: The strategy is the BEACONCHAIN_ETH_STRAT or the EIGEN strategy
    ///      - InputAddressZero: The slasher is the zero address
    function createRedistributingOperatorSets(
        address avs,
        CreateSetParamsV2[] calldata params,
        address[] calldata redistributionRecipients
    ) external;

    /// @notice Allows an AVS to add strategies to an operator set
    /// @dev Strategies MUST NOT already exist in the operator set
    /// @dev If the operatorSet is redistributing, the `BEACONCHAIN_ETH_STRAT` may not be added, since redistribution is not supported for native eth
    /// @param avs the avs to set strategies for
    /// @param operatorSetId the operator set to add strategies to
    /// @param strategies the strategies to add
    function addStrategiesToOperatorSet(
        address avs,
        uint32 operatorSetId,
        IStrategy[] calldata strategies
    ) external;

    /// @notice Allows an AVS to remove strategies from an operator set
    /// @dev Strategies MUST already exist in the operator set
    /// @param avs the avs to remove strategies for
    /// @param operatorSetId the operator set to remove strategies from
    /// @param strategies the strategies to remove
    function removeStrategiesFromOperatorSet(
        address avs,
        uint32 operatorSetId,
        IStrategy[] calldata strategies
    ) external;

    /// @notice Allows an AVS to update the slasher for an operator set
    /// @param operatorSet the operator set to update the slasher for
    /// @param slasher the new slasher
    /// @dev The new slasher will take effect after `SLASHER_CONFIGURATION_DELAY` blocks.
    /// @dev No-op if the proposed slasher is already pending and hasn't taken effect yet (delay countdown is not restarted).
    /// @dev The slasher can only be updated if it has already been set. The slasher is set either on operatorSet creation or,
    ///      for operatorSets created prior to v1.9.0, via `migrateSlashers`
    /// @dev Reverts for:
    ///      - InvalidCaller: The caller cannot update the slasher for the operator set (set via the `PermissionController`)
    ///      - InvalidOperatorSet: The operator set does not exist
    ///      - SlasherNotSet: The slasher has not been set yet
    ///      - InputAddressZero: The slasher is the zero address
    function updateSlasher(
        OperatorSet memory operatorSet,
        address slasher
    ) external;

    /// @notice Allows any address to migrate the slasher from the permission controller to the ALM
    /// @param operatorSets the list of operator sets to migrate the slasher for
    /// @dev This function is used to migrate the slasher from the permission controller to the ALM for operatorSets created prior to `v1.9.0`
    /// @dev Migrates based on the following rules:
    ///      - If there is no slasher set or the slasher in the `PermissionController`is the 0 address, the AVS address will be set as the slasher
    ///      - If there are multiple slashers set in the `PermissionController`, the first address will be set as the slasher
    /// @dev A migration can only be completed once for a given operatorSet
    /// @dev This function will be deprecated in Early Q2 2026. EigenLabs will migrate the slasher for all operatorSets created prior to `v1.9.0`
    /// @dev This function does not revert to allow for simpler offchain calling. It will no-op if:
    ///      - The operator set does not exist
    ///      - The slasher has already been set, either via migration or creation of the operatorSet
    /// @dev WARNING: Gas cost is O(appointees) per operator set due to `PermissionController.getAppointees()` call.
    ///      May exceed block gas limit for AVSs with large appointee sets. Consider batching operator sets if needed.
    function migrateSlashers(
        OperatorSet[] memory operatorSets
    ) external;
}

interface IAllocationManagerView is IAllocationManagerErrors, IAllocationManagerEvents, IAllocationManagerStorage {
    ///
    ///                         VIEW FUNCTIONS
    ///
    /// @notice Returns the number of operator sets for the AVS
    /// @param avs the AVS to query
    function getOperatorSetCount(
        address avs
    ) external view returns (uint256);

    /// @notice Returns the list of operator sets the operator has current or pending allocations/deallocations in
    /// @param operator the operator to query
    /// @return the list of operator sets the operator has current or pending allocations/deallocations in
    function getAllocatedSets(
        address operator
    ) external view returns (OperatorSet[] memory);

    /// @notice Returns the list of strategies an operator has current or pending allocations/deallocations from
    /// given a specific operator set.
    /// @param operator the operator to query
    /// @param operatorSet the operator set to query
    /// @return the list of strategies
    function getAllocatedStrategies(
        address operator,
        OperatorSet memory operatorSet
    ) external view returns (IStrategy[] memory);

    /// @notice Returns the current/pending stake allocation an operator has from a strategy to an operator set
    /// @param operator the operator to query
    /// @param operatorSet the operator set to query
    /// @param strategy the strategy to query
    /// @return the current/pending stake allocation
    function getAllocation(
        address operator,
        OperatorSet memory operatorSet,
        IStrategy strategy
    ) external view returns (Allocation memory);

    /// @notice Returns the current/pending stake allocations for multiple operators from a strategy to an operator set
    /// @param operators the operators to query
    /// @param operatorSet the operator set to query
    /// @param strategy the strategy to query
    /// @return each operator's allocation
    function getAllocations(
        address[] memory operators,
        OperatorSet memory operatorSet,
        IStrategy strategy
    ) external view returns (Allocation[] memory);

    /// @notice Given a strategy, returns a list of operator sets and corresponding stake allocations.
    /// @dev Note that this returns a list of ALL operator sets the operator has allocations in. This means
    /// some of the returned allocations may be zero.
    /// @param operator the operator to query
    /// @param strategy the strategy to query
    /// @return the list of all operator sets the operator has allocations for
    /// @return the corresponding list of allocations from the specific `strategy`
    function getStrategyAllocations(
        address operator,
        IStrategy strategy
    ) external view returns (OperatorSet[] memory, Allocation[] memory);

    /// @notice For a strategy, get the amount of magnitude that is allocated across one or more operator sets
    /// @param operator the operator to query
    /// @param strategy the strategy to get allocatable magnitude for
    /// @return currently allocated magnitude
    function getEncumberedMagnitude(
        address operator,
        IStrategy strategy
    ) external view returns (uint64);

    /// @notice For a strategy, get the amount of magnitude not currently allocated to any operator set
    /// @param operator the operator to query
    /// @param strategy the strategy to get allocatable magnitude for
    /// @return magnitude available to be allocated to an operator set
    function getAllocatableMagnitude(
        address operator,
        IStrategy strategy
    ) external view returns (uint64);

    /// @notice Returns the maximum magnitude an operator can allocate for the given strategy
    /// @dev The max magnitude of an operator starts at WAD (1e18), and is decreased anytime
    /// the operator is slashed. This value acts as a cap on the max magnitude of the operator.
    /// @param operator the operator to query
    /// @param strategy the strategy to get the max magnitude for
    /// @return the max magnitude for the strategy
    function getMaxMagnitude(
        address operator,
        IStrategy strategy
    ) external view returns (uint64);

    /// @notice Returns the maximum magnitude an operator can allocate for the given strategies
    /// @dev The max magnitude of an operator starts at WAD (1e18), and is decreased anytime
    /// the operator is slashed. This value acts as a cap on the max magnitude of the operator.
    /// @param operator the operator to query
    /// @param strategies the strategies to get the max magnitudes for
    /// @return the max magnitudes for each strategy
    function getMaxMagnitudes(
        address operator,
        IStrategy[] calldata strategies
    ) external view returns (uint64[] memory);

    /// @notice Returns the maximum magnitudes each operator can allocate for the given strategy
    /// @dev The max magnitude of an operator starts at WAD (1e18), and is decreased anytime
    /// the operator is slashed. This value acts as a cap on the max magnitude of the operator.
    /// @param operators the operators to query
    /// @param strategy the strategy to get the max magnitudes for
    /// @return the max magnitudes for each operator
    function getMaxMagnitudes(
        address[] calldata operators,
        IStrategy strategy
    ) external view returns (uint64[] memory);

    /// @notice Returns the maximum magnitude an operator can allocate for the given strategies
    /// at a given block number
    /// @dev The max magnitude of an operator starts at WAD (1e18), and is decreased anytime
    /// the operator is slashed. This value acts as a cap on the max magnitude of the operator.
    /// @param operator the operator to query
    /// @param strategies the strategies to get the max magnitudes for
    /// @param blockNumber the blockNumber at which to check the max magnitudes
    /// @return the max magnitudes for each strategy
    function getMaxMagnitudesAtBlock(
        address operator,
        IStrategy[] calldata strategies,
        uint32 blockNumber
    ) external view returns (uint64[] memory);

    /// @notice Returns the time in blocks between an operator allocating slashable magnitude
    /// and the magnitude becoming slashable. If the delay has not been set, `isSet` will be false.
    /// @dev The operator must have a configured delay before allocating magnitude
    /// @param operator The operator to query
    /// @return isSet Whether the operator has configured a delay
    /// @return delay The time in blocks between allocating magnitude and magnitude becoming slashable
    function getAllocationDelay(
        address operator
    ) external view returns (bool isSet, uint32 delay);

    /// @notice Returns a list of all operator sets the operator is registered for
    /// @param operator The operator address to query.
    function getRegisteredSets(
        address operator
    ) external view returns (OperatorSet[] memory operatorSets);

    /// @notice Returns whether the operator is registered for the operator set
    /// @param operator The operator to query
    /// @param operatorSet The operator set to query
    function isMemberOfOperatorSet(
        address operator,
        OperatorSet memory operatorSet
    ) external view returns (bool);

    /// @notice Returns whether the operator set exists
    function isOperatorSet(
        OperatorSet memory operatorSet
    ) external view returns (bool);

    /// @notice Returns all the operators registered to an operator set
    /// @param operatorSet The operatorSet to query.
    function getMembers(
        OperatorSet memory operatorSet
    ) external view returns (address[] memory operators);

    /// @notice Returns the number of operators registered to an operatorSet.
    /// @param operatorSet The operatorSet to get the member count for
    function getMemberCount(
        OperatorSet memory operatorSet
    ) external view returns (uint256);

    /// @notice Returns the address that handles registration/deregistration for the AVS
    /// If not set, defaults to the input address (`avs`)
    function getAVSRegistrar(
        address avs
    ) external view returns (IAVSRegistrar);

    /// @notice Returns an array of strategies in the operatorSet.
    /// @param operatorSet The operatorSet to query.
    function getStrategiesInOperatorSet(
        OperatorSet memory operatorSet
    ) external view returns (IStrategy[] memory strategies);

    /// @notice Returns the minimum amount of stake that will be slashable as of some future block,
    /// according to each operator's allocation from each strategy to the operator set. Note that this function
    /// will return 0 for the slashable stake if the operator is not slashable at the time of the call.
    /// @dev This method queries actual delegated stakes in the DelegationManager and applies
    /// each operator's allocation to the stake to produce the slashable stake each allocation
    /// represents. This method does not consider slashable stake in the withdrawal queue even though there could be
    /// slashable stake in the queue.
    /// @dev This minimum takes into account `futureBlock`, and will omit any pending magnitude
    /// diffs that will not be in effect as of `futureBlock`. NOTE that in order to get the true
    /// minimum slashable stake as of some future block, `futureBlock` MUST be greater than block.number
    /// @dev NOTE that `futureBlock` should be fewer than `DEALLOCATION_DELAY` blocks in the future,
    /// or the values returned from this method may not be accurate due to deallocations.
    /// @param operatorSet the operator set to query
    /// @param operators the list of operators whose slashable stakes will be returned
    /// @param strategies the strategies that each slashable stake corresponds to
    /// @param futureBlock the block at which to get allocation information. Should be a future block.
    function getMinimumSlashableStake(
        OperatorSet memory operatorSet,
        address[] memory operators,
        IStrategy[] memory strategies,
        uint32 futureBlock
    ) external view returns (uint256[][] memory slashableStake);

    /// @notice Returns the current allocated stake, irrespective of the operator's slashable status for the operatorSet.
    /// @param operatorSet the operator set to query
    /// @param operators the operators to query
    /// @param strategies the strategies to query
    function getAllocatedStake(
        OperatorSet memory operatorSet,
        address[] memory operators,
        IStrategy[] memory strategies
    ) external view returns (uint256[][] memory slashableStake);

    /// @notice Returns whether an operator is slashable by an operator set.
    /// This returns true if the operator is registered or their slashableUntil block has not passed.
    /// This is because even when operators are deregistered, they still remain slashable for a period of time.
    /// @param operator the operator to check slashability for
    /// @param operatorSet the operator set to check slashability for
    function isOperatorSlashable(
        address operator,
        OperatorSet memory operatorSet
    ) external view returns (bool);

    /// @notice Returns the address that can slash a given operator set.
    /// @param operatorSet The operator set to query.
    /// @return The address that can slash the operator set. Returns `address(0)` if the operator set doesn't exist.
    /// @dev If there is a pending slasher that can be applied after the `effectBlock`, the pending slasher will be returned.
    function getSlasher(
        OperatorSet memory operatorSet
    ) external view returns (address);

    /// @notice Returns pending slasher for a given operator set.
    /// @param operatorSet The operator set to query.
    /// @return pendingSlasher The pending slasher for the operator set. Returns `address(0)` if there is no pending slasher or the operator set doesn't exist.
    /// @return effectBlock The block at which the pending slasher will take effect. Returns `0` if there is no pending slasher or the operator set doesn't exist.
    function getPendingSlasher(
        OperatorSet memory operatorSet
    ) external view returns (address pendingSlasher, uint32 effectBlock);

    /// @notice Returns the address where slashed funds will be sent for a given operator set.
    /// @param operatorSet The Operator Set to query.
    /// @return For redistributing Operator Sets, returns the configured redistribution address set during Operator Set creation.
    ///         For non-redistributing operator sets, returns the `DEFAULT_BURN_ADDRESS`.
    function getRedistributionRecipient(
        OperatorSet memory operatorSet
    ) external view returns (address);

    /// @notice Returns whether a given operator set supports redistribution
    /// or not when funds are slashed and burned from EigenLayer.
    /// @param operatorSet The Operator Set to query.
    /// @return For redistributing Operator Sets, returns true.
    ///         For non-redistributing Operator Sets, returns false.
    function isRedistributingOperatorSet(
        OperatorSet memory operatorSet
    ) external view returns (bool);

    /// @notice Returns the number of slashes for a given operator set.
    /// @param operatorSet The operator set to query.
    /// @return The number of slashes for the operator set.
    function getSlashCount(
        OperatorSet memory operatorSet
    ) external view returns (uint256);

    /// @notice Returns whether an operator is slashable by a redistributing operator set.
    /// @param operator The operator to query.
    function isOperatorRedistributable(
        address operator
    ) external view returns (bool);
}

interface IAllocationManager is IAllocationManagerActions, IAllocationManagerView, IPausable {}

// Source: src/contracts/interfaces/IAVSDirectory.sol
interface IAVSDirectoryErrors {
    /// Operator Status
    /// @dev Thrown when an operator does not exist in the DelegationManager
    error OperatorNotRegisteredToEigenLayer();
    /// @dev Thrown when an operator is already registered to an AVS.
    error OperatorNotRegisteredToAVS();
    /// @dev Thrown when `operator` is already registered to the AVS.
    error OperatorAlreadyRegisteredToAVS();
    /// @dev Thrown when attempting to spend a spent eip-712 salt.
    error SaltSpent();
}

interface IAVSDirectoryTypes {
    /// @notice Enum representing the registration status of an operator with an AVS.
    /// @notice Only used by legacy M2 AVSs that have not integrated with operatorSets.
    enum OperatorAVSRegistrationStatus {
        UNREGISTERED, // Operator not registered to AVS
        REGISTERED // Operator registered to AVS
    }

    /// @notice Struct representing the registration status of an operator with an operator set.
    /// Keeps track of last deregistered timestamp for slashability concerns.
    /// @param registered whether the operator is registered with the operator set
    /// @param lastDeregisteredTimestamp the timestamp at which the operator was last deregistered
    struct OperatorSetRegistrationStatus {
        bool registered;
        uint32 lastDeregisteredTimestamp;
    }
}

interface IAVSDirectoryEvents is IAVSDirectoryTypes {
    ///  @notice Emitted when an operator's registration status with an AVS id updated
    ///  @notice Only used by legacy M2 AVSs that have not integrated with operatorSets.
    event OperatorAVSRegistrationStatusUpdated(
        address indexed operator,
        address indexed avs,
        OperatorAVSRegistrationStatus status
    );

    /// @notice Emitted when an AVS updates their metadata URI (Uniform Resource Identifier).
    /// @dev The URI is never stored; it is simply emitted through an event for off-chain indexing.
    event AVSMetadataURIUpdated(address indexed avs, string metadataURI);
}

interface IAVSDirectory is IAVSDirectoryEvents, IAVSDirectoryErrors, ISignatureUtilsMixin {
    ///
    ///                         EXTERNAL FUNCTIONS
    ///
    /// @dev Initializes the addresses of the initial owner and paused status.
    function initialize(
        address initialOwner,
        uint256 initialPausedStatus
    ) external;

    ///  @notice Called by an AVS to emit an `AVSMetadataURIUpdated` event indicating the information has updated.
    ///
    ///  @param metadataURI The URI for metadata associated with an AVS.
    ///
    ///  @dev Note that the `metadataURI` is *never stored* and is only emitted in the `AVSMetadataURIUpdated` event.
    function updateAVSMetadataURI(
        string calldata metadataURI
    ) external;

    /// @notice Called by an operator to cancel a salt that has been used to register with an AVS.
    ///
    /// @param salt A unique and single use value associated with the approver signature.
    function cancelSalt(
        bytes32 salt
    ) external;

    ///  @notice Legacy function called by the AVS's service manager contract
    /// to register an operator with the AVS. NOTE: this function will be deprecated in a future release
    /// after the slashing release. New AVSs should use `registerForOperatorSets` instead.
    ///
    ///  @param operator The address of the operator to register.
    ///  @param operatorSignature The signature, salt, and expiry of the operator's signature.
    ///
    ///  @dev msg.sender must be the AVS.
    ///  @dev Only used by legacy M2 AVSs that have not integrated with operator sets.
    function registerOperatorToAVS(
        address operator,
        ISignatureUtilsMixinTypes.SignatureWithSaltAndExpiry memory operatorSignature
    ) external;

    ///  @notice Legacy function called by an AVS to deregister an operator from the AVS.
    /// NOTE: this function will be deprecated in a future release after the slashing release.
    /// New AVSs integrating should use `deregisterOperatorFromOperatorSets` instead.
    ///
    ///  @param operator The address of the operator to deregister.
    ///
    ///  @dev Only used by legacy M2 AVSs that have not integrated with operator sets.
    function deregisterOperatorFromAVS(
        address operator
    ) external;

    ///
    ///                         VIEW FUNCTIONS
    ///
    function operatorSaltIsSpent(
        address operator,
        bytes32 salt
    ) external view returns (bool);

    ///  @notice Calculates the digest hash to be signed by an operator to register with an AVS.
    ///
    ///  @param operator The account registering as an operator.
    ///  @param avs The AVS the operator is registering with.
    ///  @param salt A unique and single-use value associated with the approver's signature.
    ///  @param expiry The time after which the approver's signature becomes invalid.
    function calculateOperatorAVSRegistrationDigestHash(
        address operator,
        address avs,
        bytes32 salt,
        uint256 expiry
    ) external view returns (bytes32);

    /// @notice The EIP-712 typehash for the Registration struct used by the contract.
    function OPERATOR_AVS_REGISTRATION_TYPEHASH() external view returns (bytes32);

    /// @notice The EIP-712 typehash for the OperatorSetRegistration struct used by the contract.
    function OPERATOR_SET_REGISTRATION_TYPEHASH() external view returns (bytes32);
}

// Source: src/contracts/core/storage/StrategyManagerStorage.sol
/// @title Storage variables for the `StrategyManager` contract.
/// @author Layr Labs, Inc.
/// @notice Terms of Service: https://docs.eigenlayer.xyz/overview/terms-of-service
/// @notice This storage contract is separate from the logic to simplify the upgrade process.
abstract contract StrategyManagerStorage is IStrategyManager {
    // Constants

    /// @notice The EIP-712 typehash for the deposit struct used by the contract
    bytes32 public constant DEPOSIT_TYPEHASH =
        keccak256("Deposit(address staker,address strategy,address token,uint256 amount,uint256 nonce,uint256 expiry)");

    // maximum length of dynamic arrays in `stakerStrategyList` mapping, for sanity's sake
    uint8 internal constant MAX_STAKER_STRATEGY_LIST_LENGTH = 32;

    // index for flag that pauses deposits when set
    uint8 internal constant PAUSED_DEPOSITS = 0;

    /// @dev Index for flag that pauses clearing of burn or redistributable shares when set.
    uint8 internal constant PAUSED_BURNING_AND_REDISTRIBUTION = 1;

    /// @notice The number of blocks that must elapse after a slash before its shares can be cleared.
    /// @dev Approximately 7 days at 12-second block times.
    uint32 public constant SLASH_RESOLUTION_DELAY_BLOCKS = 50_400;

    /// @notice default address for burning slashed shares and transferring underlying tokens
    address public constant DEFAULT_BURN_ADDRESS = 0x00000000000000000000000000000000000E16E4;

    // Immutables

    IAllocationManager public immutable allocationManager;

    IDelegationManager public immutable delegation;

    // Mutatables

    /// @dev Do not remove, deprecated storage.
    bytes32 internal __deprecated_DOMAIN_SEPARATOR;

    /// @notice Returns the signature `nonce` for each `signer`.
    mapping(address signer => uint256 nonce) public nonces;

    /// @notice Returns the permissioned address that can whitelist strategies.
    address public strategyWhitelister;

    /// @dev Do not remove, deprecated storage.
    uint256 private __deprecated_withdrawalDelayBlocks;

    /// @notice Returns the number of deposited `shares` for a `staker` for a given `strategy`.
    /// @dev All of these shares may not be withdrawable if the staker has delegated to an operator that has been slashed.
    mapping(address staker => mapping(IStrategy strategy => uint256 shares)) public stakerDepositShares;

    /// @notice Returns a list of the `strategies` that a `staker` is currently staking in.
    mapping(address staker => IStrategy[] strategies) public stakerStrategyList;

    /// @dev Do not remove, deprecated storage.
    mapping(bytes32 withdrawalRoot => bool pending) private __deprecated_withdrawalRootPending;

    /// @dev Do not remove, deprecated storage.
    mapping(address staker => uint256 totalQueued) private __deprecated_numWithdrawalsQueued;

    /// @notice Returns whether a `strategy` is `whitelisted` for deposits.
    mapping(IStrategy strategy => bool whitelisted) public strategyIsWhitelistedForDeposit;

    /// @dev Do not remove, deprecated storage.
    mapping(address avs => uint256 shares) private __deprecated_beaconChainETHSharesToDecrementOnWithdrawal;

    /// @dev Do not remove, deprecated storage.
    mapping(IStrategy strategy => bool) private __deprecated_thirdPartyTransfersForbidden;

    /// @notice Returns the amount of `shares` that have been slashed on EigenLayer but not burned yet. Takes 3 storage slots.
    /// @dev After the redistribution upgrade, this storage variable is no longer used, and will be deprecated.
    EnumerableMap.AddressToUintMap internal burnableShares;

    /// @notice Returns the amount of `shares` that have been slashed on EigenLayer but not marked for burning or redistribution yet.
    mapping(bytes32 operatorSetKey => mapping(uint256 slashId => EnumerableMap.AddressToUintMap)) internal
        _burnOrRedistributableShares;

    /// @notice Returns a list of operator sets who have pending burn or redistributable shares.
    EnumerableSet.Bytes32Set internal _pendingOperatorSets;

    /// @notice Returns a list of slash ids for each operator set who have pending burn or redistributable shares.
    mapping(bytes32 operatorSetKey => EnumerableSet.UintSet) internal _pendingSlashIds;

    /// @notice The block number after which a slash's shares may be cleared.
    /// @dev Set to `block.number + SLASH_RESOLUTION_DELAY_BLOCKS` when a slash is first recorded.
    /// @dev Pre-upgrade entries will have a zero value, allowing immediate clearing (grandfather behaviour).
    mapping(bytes32 operatorSetKey => mapping(uint256 slashId => uint32 resolutionBlock)) internal
        _slashResolutionBlock;

    // Construction

    /// @param _delegation The delegation contract of EigenLayer.
    constructor(
        IAllocationManager _allocationManager,
        IDelegationManager _delegation
    ) {
        allocationManager = _allocationManager;
        delegation = _delegation;
    }

    /// @dev This empty reserved space is put in place to allow future versions to add new
    /// variables without shifting down storage in the inheritance chain.
    /// See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[31] private __gap;
}

// Source: src/contracts/core/StrategyManager.sol
/// @title The primary entry- and exit-point for funds into and out of EigenLayer.
/// @author Layr Labs, Inc.
/// @notice Terms of Service: https://docs.eigenlayer.xyz/overview/terms-of-service
/// @notice This contract is for managing deposits in different strategies. The main
/// functionalities are:
/// - adding and removing strategies that any delegator can deposit into
/// - enabling deposit of assets into specified strategy(s)
contract EigenLayerStrategyManager is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    Pausable,
    StrategyManagerStorage,
    SignatureUtilsMixin
{
    using OperatorSetLib for *;
    using SlashingLib for *;
    using SafeERC20 for IERC20;
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.UintSet;

    modifier onlyStrategyWhitelister() {
        require(msg.sender == strategyWhitelister, OnlyStrategyWhitelister());
        _;
    }

    modifier onlyStrategiesWhitelistedForDeposit(
        IStrategy strategy
    ) {
        require(strategyIsWhitelistedForDeposit[strategy], StrategyNotWhitelisted());
        _;
    }

    modifier onlyDelegationManager() {
        require(msg.sender == address(delegation), OnlyDelegationManager());
        _;
    }

    /// @param _delegation The delegation contract of EigenLayer.
    constructor(
        IAllocationManager _allocationManager,
        IDelegationManager _delegation,
        IPauserRegistry _pauserRegistry,
        string memory _version
    ) StrategyManagerStorage(_allocationManager, _delegation) Pausable(_pauserRegistry) SignatureUtilsMixin(_version) {
        _disableInitializers();
    }

    // EXTERNAL FUNCTIONS

    /// @notice Initializes the strategy manager contract. Sets the `pauserRegistry` (currently **not** modifiable after being set),
    /// and transfers contract ownership to the specified `initialOwner`.
    /// @param initialOwner Ownership of this contract is transferred to this address.
    /// @param initialStrategyWhitelister The initial value of `strategyWhitelister` to set.
    function initialize(
        address initialOwner,
        address initialStrategyWhitelister,
        uint256 initialPausedStatus
    ) external initializer {
        _setPausedStatus(initialPausedStatus);
        _transferOwnership(initialOwner);
        _setStrategyWhitelister(initialStrategyWhitelister);
    }

    /// @inheritdoc IStrategyManager
    function depositIntoStrategy(
        IStrategy strategy,
        IERC20 token,
        uint256 amount
    ) external onlyWhenNotPaused(PAUSED_DEPOSITS) nonReentrant returns (uint256 depositShares) {
        depositShares = _depositIntoStrategy(msg.sender, strategy, token, amount);
    }

    /// @inheritdoc IStrategyManager
    function depositIntoStrategyWithSignature(
        IStrategy strategy,
        IERC20 token,
        uint256 amount,
        address staker,
        uint256 expiry,
        bytes memory signature
    ) external onlyWhenNotPaused(PAUSED_DEPOSITS) nonReentrant returns (uint256 depositShares) {
        // Cache staker's nonce to avoid sloads.
        uint256 nonce = nonces[staker];
        // Assert that the signature is valid.
        _checkIsValidSignatureNow({
            signer: staker,
            signableDigest: calculateStrategyDepositDigestHash(staker, strategy, token, amount, nonce, expiry),
            signature: signature,
            expiry: expiry
        });
        // Increment the nonce for the staker.
        unchecked {
            nonces[staker] = nonce + 1;
        }
        // deposit the tokens (from the `msg.sender`) and credit the new shares to the `staker`
        depositShares = _depositIntoStrategy(staker, strategy, token, amount);
    }

    /// @inheritdoc IShareManager
    function removeDepositShares(
        address staker,
        IStrategy strategy,
        uint256 depositSharesToRemove
    ) external onlyDelegationManager nonReentrant returns (uint256) {
        return _removeDepositShares(staker, strategy, depositSharesToRemove);
    }

    /// @inheritdoc IShareManager
    function addShares(
        address staker,
        IStrategy strategy,
        uint256 shares
    ) external onlyDelegationManager nonReentrant returns (uint256, uint256) {
        return _addShares(staker, strategy, shares);
    }

    /// @inheritdoc IShareManager
    function withdrawSharesAsTokens(
        address staker,
        IStrategy strategy,
        IERC20 token,
        uint256 shares
    ) external onlyDelegationManager nonReentrant {
        strategy.withdraw(staker, token, shares);
    }

    /// @inheritdoc IShareManager
    function increaseBurnOrRedistributableShares(
        OperatorSet calldata operatorSet,
        uint256 slashId,
        IStrategy strategy,
        uint256 sharesToBurn
    ) external onlyDelegationManager nonReentrant {
        // Create storage pointer for readability.
        EnumerableMap.AddressToUintMap storage burnOrRedistributableShares =
            _burnOrRedistributableShares[operatorSet.key()][slashId];

        // Sanity check that the strategy is not already in the slash's burn or redistributable shares.
        // This should never happen because the `AllocationManager` ensures that strategies for a given slash are unique.
        // Add the shares to the operator set's burn or redistributable shares.
        require(burnOrRedistributableShares.set(address(strategy), sharesToBurn), StrategyAlreadyInSlash());

        // NOTE: Duplicate operator sets and slash ids will not revert, but will not be added.
        _pendingOperatorSets.add(operatorSet.key());
        // Set the resolution block the first time this slashId is recorded for this operator set.
        if (_pendingSlashIds[operatorSet.key()].add(slashId)) {
            uint32 resolutionBlock = uint32(block.number) + SLASH_RESOLUTION_DELAY_BLOCKS;
            _slashResolutionBlock[operatorSet.key()][slashId] = resolutionBlock;
            emit SlashResolutionBlockSet(operatorSet, slashId, resolutionBlock);
        }

        emit BurnOrRedistributableSharesIncreased(operatorSet, slashId, strategy, sharesToBurn);
    }

    /// @inheritdoc IStrategyManager
    function clearBurnOrRedistributableShares(
        OperatorSet calldata operatorSet,
        uint256 slashId
    ) external onlyWhenNotPaused(PAUSED_BURNING_AND_REDISTRIBUTION) nonReentrant returns (uint256[] memory) {
        // Pause/delay are checked once here; per-strategy iteration shares the same slashId resolution block.
        require(block.number > _slashResolutionBlock[operatorSet.key()][slashId], SlashResolutionDelayNotElapsed());

        // Get the strategies to clear.
        address[] memory strategies = _burnOrRedistributableShares[operatorSet.key()][slashId].keys();
        uint256 length = strategies.length;
        uint256[] memory amounts = new uint256[](length);

        // Note: We don't need to iterate backwards since we're indexing into the `EnumerableMap` directly.
        for (uint256 i = 0; i < length; ++i) {
            amounts[i] = _clearBurnOrRedistributableShares({
                operatorSet: operatorSet,
                slashId: slashId,
                strategy: IStrategy(strategies[i]),
                recipient: allocationManager.getRedistributionRecipient(operatorSet)
            });
        }

        return amounts;
    }

    /// @inheritdoc IStrategyManager
    function clearBurnOrRedistributableSharesByStrategy(
        OperatorSet calldata operatorSet,
        uint256 slashId,
        IStrategy strategy
    ) external onlyWhenNotPaused(PAUSED_BURNING_AND_REDISTRIBUTION) nonReentrant returns (uint256) {
        require(block.number > _slashResolutionBlock[operatorSet.key()][slashId], SlashResolutionDelayNotElapsed());
        return _clearBurnOrRedistributableShares({
            operatorSet: operatorSet,
            slashId: slashId,
            strategy: strategy,
            recipient: allocationManager.getRedistributionRecipient(operatorSet)
        });
    }

    /// @inheritdoc IStrategyManager
    function burnShares(
        IStrategy strategy
    ) external onlyWhenNotPaused(PAUSED_BURNING_AND_REDISTRIBUTION) nonReentrant {
        (, uint256 sharesToBurn) = EnumerableMap.tryGet(burnableShares, address(strategy));
        EnumerableMap.remove(burnableShares, address(strategy));
        emit BurnableSharesDecreased(strategy, sharesToBurn);

        // Burning acts like withdrawing, except that the destination is to the burn address.
        // If we have no shares to burn, we don't need to call the strategy.
        if (sharesToBurn != 0) {
            strategy.withdraw(DEFAULT_BURN_ADDRESS, strategy.underlyingToken(), sharesToBurn);
        }
    }

    /// @inheritdoc IStrategyManager
    function setStrategyWhitelister(
        address newStrategyWhitelister
    ) external onlyOwner nonReentrant {
        _setStrategyWhitelister(newStrategyWhitelister);
    }

    /// @inheritdoc IStrategyManager
    function addStrategiesToDepositWhitelist(
        IStrategy[] calldata strategiesToWhitelist
    ) external onlyStrategyWhitelister nonReentrant {
        uint256 strategiesToWhitelistLength = strategiesToWhitelist.length;
        for (uint256 i = 0; i < strategiesToWhitelistLength; ++i) {
            // change storage and emit event only if strategy is not already in whitelist
            if (!strategyIsWhitelistedForDeposit[strategiesToWhitelist[i]]) {
                strategyIsWhitelistedForDeposit[strategiesToWhitelist[i]] = true;
                emit StrategyAddedToDepositWhitelist(strategiesToWhitelist[i]);
            }
        }
    }

    /// @inheritdoc IStrategyManager
    function removeStrategiesFromDepositWhitelist(
        IStrategy[] calldata strategiesToRemoveFromWhitelist
    ) external onlyStrategyWhitelister nonReentrant {
        uint256 strategiesToRemoveFromWhitelistLength = strategiesToRemoveFromWhitelist.length;
        for (uint256 i = 0; i < strategiesToRemoveFromWhitelistLength; ++i) {
            // change storage and emit event only if strategy is already in whitelist
            if (strategyIsWhitelistedForDeposit[strategiesToRemoveFromWhitelist[i]]) {
                strategyIsWhitelistedForDeposit[strategiesToRemoveFromWhitelist[i]] = false;
                emit StrategyRemovedFromDepositWhitelist(strategiesToRemoveFromWhitelist[i]);
            }
        }
    }

    // INTERNAL FUNCTIONS

    /// @notice This function adds `shares` for a given `strategy` to the `staker` and runs through the necessary update logic.
    /// @param staker The address to add shares to
    /// @param strategy The Strategy in which the `staker` is receiving shares
    /// @param shares The amount of shares to grant to the `staker`
    /// @dev In particular, this function calls `delegation.increaseDelegatedShares(staker, strategy, shares)` to ensure that all
    /// delegated shares are tracked, increases the stored share amount in `stakerDepositShares[staker][strategy]`, and adds `strategy`
    /// to the `staker`'s list of strategies, if it is not in the list already.
    function _addShares(
        address staker,
        IStrategy strategy,
        uint256 shares
    ) internal returns (uint256, uint256) {
        // sanity checks on inputs
        require(staker != address(0), StakerAddressZero());
        require(shares != 0, SharesAmountZero());

        // allow the strategy to veto or enforce constraints on adding shares
        strategy.beforeAddShares(staker, shares);

        uint256 prevDepositShares = stakerDepositShares[staker][strategy];

        // if they dont have prevDepositShares of this strategy, add it to their strats
        if (prevDepositShares == 0) {
            require(stakerStrategyList[staker].length < MAX_STAKER_STRATEGY_LIST_LENGTH, MaxStrategiesExceeded());
            stakerStrategyList[staker].push(strategy);
        }

        // add the returned depositedShares to their existing shares for this strategy
        stakerDepositShares[staker][strategy] = prevDepositShares + shares;

        emit Deposit(staker, strategy, shares);
        return (prevDepositShares, shares);
    }

    /// @notice Internal function in which `amount` of ERC20 `token` is transferred from `msg.sender` to the Strategy-type contract
    /// `strategy`, with the resulting shares credited to `staker`.
    /// @param staker The address that will be credited with the new shares.
    /// @param strategy The Strategy contract to deposit into.
    /// @param token The ERC20 token to deposit.
    /// @param amount The amount of `token` to deposit.
    /// @return shares The amount of *new* shares in `strategy` that have been credited to the `staker`.
    function _depositIntoStrategy(
        address staker,
        IStrategy strategy,
        IERC20 token,
        uint256 amount
    ) internal onlyStrategiesWhitelistedForDeposit(strategy) returns (uint256 shares) {
        // transfer tokens from the sender to the strategy
        token.safeTransferFrom(msg.sender, address(strategy), amount);

        // deposit the assets into the specified strategy and get the equivalent amount of shares in that strategy
        shares = strategy.deposit(token, amount);

        // add the returned shares to the staker's existing shares for this strategy
        (uint256 prevDepositShares, uint256 addedShares) = _addShares(staker, strategy, shares);

        // Increase shares delegated to operator
        delegation.increaseDelegatedShares({
            staker: staker,
            strategy: strategy,
            prevDepositShares: prevDepositShares,
            addedShares: addedShares
        });

        return shares;
    }

    /// @notice Decreases the shares that `staker` holds in `strategy` by `depositSharesToRemove`.
    /// @param staker The address to decrement shares from
    /// @param strategy The strategy for which the `staker`'s shares are being decremented
    /// @param depositSharesToRemove The amount of deposit shares to decrement
    /// @dev If the amount of shares represents all of the staker`s shares in said strategy,
    /// then the strategy is removed from stakerStrategyList[staker] and 'true' is returned. Otherwise 'false' is returned.
    /// Also returns the user's updated deposit shares after decrement.
    function _removeDepositShares(
        address staker,
        IStrategy strategy,
        uint256 depositSharesToRemove
    ) internal returns (uint256) {
        // sanity checks on inputs
        require(depositSharesToRemove != 0, SharesAmountZero());

        //check that the user has sufficient shares
        uint256 userDepositShares = stakerDepositShares[staker][strategy];

        // This check technically shouldn't actually ever revert because depositSharesToRemove is already
        // checked to not exceed max amount of shares when the withdrawal was queued in the DelegationManager
        require(depositSharesToRemove <= userDepositShares, SharesAmountTooHigh());

        // allow the strategy to veto or enforce constraints on removing shares
        strategy.beforeRemoveShares(staker, depositSharesToRemove);

        userDepositShares = userDepositShares - depositSharesToRemove;

        // subtract the shares from the staker's existing shares for this strategy
        stakerDepositShares[staker][strategy] = userDepositShares;

        // if no existing shares, remove the strategy from the staker's dynamic array of strategies
        if (userDepositShares == 0) {
            _removeStrategyFromStakerStrategyList(staker, strategy);
        }

        return userDepositShares;
    }

    /// @notice Removes `strategy` from `staker`'s dynamic array of strategies, i.e. from `stakerStrategyList[staker]`
    /// @param staker The user whose array will have an entry removed
    /// @param strategy The Strategy to remove from `stakerStrategyList[staker]`
    function _removeStrategyFromStakerStrategyList(
        address staker,
        IStrategy strategy
    ) internal {
        //loop through all of the strategies, find the right one, then replace
        uint256 stratsLength = stakerStrategyList[staker].length;
        uint256 j = 0;
        for (; j < stratsLength; ++j) {
            if (stakerStrategyList[staker][j] == strategy) {
                //replace the strategy with the last strategy in the list
                stakerStrategyList[staker][j] = stakerStrategyList[staker][stakerStrategyList[staker].length - 1];
                break;
            }
        }
        // if we didn't find the strategy, revert
        require(j != stratsLength, StrategyNotFound());
        // pop off the last entry in the list of strategies
        stakerStrategyList[staker].pop();
    }

    /// @notice Clears burn/redistributable shares and sends underlying tokens to recipient.
    /// @param operatorSet The operator set to clear the shares for.
    /// @param slashId The slash id to clear the shares for.
    /// @param strategy The strategy to clear the shares for.
    /// @param recipient The recipient to withdraw the shares to.
    /// @dev Pause and slash-resolution-delay checks are enforced by the external callers
    ///      (`clearBurnOrRedistributableShares` / `clearBurnOrRedistributableSharesByStrategy`).
    function _clearBurnOrRedistributableShares(
        OperatorSet calldata operatorSet,
        uint256 slashId,
        IStrategy strategy,
        address recipient
    ) internal returns (uint256) {
        EnumerableMap.AddressToUintMap storage burnOrRedistributableShares =
            _burnOrRedistributableShares[operatorSet.key()][slashId];

        (, uint256 sharesToRemove) = burnOrRedistributableShares.tryGet(address(strategy));
        burnOrRedistributableShares.remove(address(strategy));

        uint256 amountOut;
        if (sharesToRemove != 0) {
            // Withdraw the shares to the burn address.
            amountOut = IStrategy(strategy)
                .withdraw({
                    recipient: recipient,
                    token: IStrategy(strategy).underlyingToken(),
                    amountShares: sharesToRemove
                });

            // Emit an event to notify the that burnable shares have been decreased.
            emit BurnOrRedistributableSharesDecreased(operatorSet, slashId, strategy, sharesToRemove);
        }

        uint256 remainingStrategies = burnOrRedistributableShares.length();

        // If there are no more strategies to burn or redistribute...
        if (remainingStrategies == 0) {
            // Remove the slash id from the pending slash ids.
            _pendingSlashIds[operatorSet.key()].remove(slashId);
            // Remove the slash resolution block for this slash id.
            delete _slashResolutionBlock[operatorSet.key()][slashId];

            // If there are no more pending slash ids for this operator set, remove the operator set from the pending operator sets.
            if (_pendingSlashIds[operatorSet.key()].length() == 0) {
                _pendingOperatorSets.remove(operatorSet.key());
            }
        }

        return amountOut;
    }

    /// @notice Internal function for modifying the `strategyWhitelister`. Used inside of the `setStrategyWhitelister` and `initialize` functions.
    /// @param newStrategyWhitelister The new address for the `strategyWhitelister` to take.
    function _setStrategyWhitelister(
        address newStrategyWhitelister
    ) internal {
        emit StrategyWhitelisterChanged(strategyWhitelister, newStrategyWhitelister);
        strategyWhitelister = newStrategyWhitelister;
    }

    // VIEW FUNCTIONS

    /// @inheritdoc IStrategyManager
    function getDeposits(
        address staker
    ) external view returns (IStrategy[] memory, uint256[] memory) {
        uint256 strategiesLength = stakerStrategyList[staker].length;
        uint256[] memory depositedShares = new uint256[](strategiesLength);

        for (uint256 i = 0; i < strategiesLength; ++i) {
            depositedShares[i] = stakerDepositShares[staker][stakerStrategyList[staker][i]];
        }
        return (stakerStrategyList[staker], depositedShares);
    }

    function getStakerStrategyList(
        address staker
    ) external view returns (IStrategy[] memory) {
        return stakerStrategyList[staker];
    }

    /// @inheritdoc IStrategyManager
    function stakerStrategyListLength(
        address staker
    ) external view returns (uint256) {
        return stakerStrategyList[staker].length;
    }

    /// @inheritdoc IStrategyManager
    function calculateStrategyDepositDigestHash(
        address staker,
        IStrategy strategy,
        IERC20 token,
        uint256 amount,
        uint256 nonce,
        uint256 expiry
    ) public view returns (bytes32) {
        /// forgefmt: disable-next-item
        return _calculateSignableDigest(
            keccak256(
                abi.encode(
                    DEPOSIT_TYPEHASH, 
                    staker, 
                    strategy, 
                    token, 
                    amount, 
                    nonce, 
                    expiry
                )
            )
        );
    }

    /// @inheritdoc IStrategyManager
    function getBurnOrRedistributableShares(
        OperatorSet calldata operatorSet,
        uint256 slashId
    ) external view returns (IStrategy[] memory, uint256[] memory) {
        // Store the data structure for readability
        EnumerableMap.AddressToUintMap storage burnOrRedistributableShares =
            _burnOrRedistributableShares[operatorSet.key()][slashId];

        address[] memory keys = burnOrRedistributableShares.keys();
        IStrategy[] memory strategies = new IStrategy[](keys.length);
        uint256[] memory shares = new uint256[](keys.length);

        for (uint256 i = 0; i < keys.length; ++i) {
            strategies[i] = IStrategy(keys[i]);
            (, shares[i]) = burnOrRedistributableShares.tryGet(keys[i]);
        }

        return (strategies, shares);
    }

    /// @inheritdoc IStrategyManager
    function getBurnOrRedistributableShares(
        OperatorSet calldata operatorSet,
        uint256 slashId,
        IStrategy strategy
    ) external view returns (uint256) {
        (, uint256 shares) = _burnOrRedistributableShares[operatorSet.key()][slashId].tryGet(address(strategy));
        return shares;
    }

    /// @inheritdoc IStrategyManager
    function getBurnOrRedistributableCount(
        OperatorSet calldata operatorSet,
        uint256 slashId
    ) external view returns (uint256) {
        return _burnOrRedistributableShares[operatorSet.key()][slashId].length();
    }

    /// @inheritdoc IStrategyManager
    function getBurnableShares(
        IStrategy strategy
    ) external view returns (uint256) {
        (, uint256 shares) = EnumerableMap.tryGet(burnableShares, address(strategy));
        return shares;
    }

    /// @inheritdoc IStrategyManager
    function getStrategiesWithBurnableShares() external view returns (address[] memory, uint256[] memory) {
        uint256 totalEntries = EnumerableMap.length(burnableShares);

        address[] memory strategies = new address[](totalEntries);
        uint256[] memory shares = new uint256[](totalEntries);

        for (uint256 i = 0; i < totalEntries; i++) {
            (address strategy, uint256 shareAmount) = EnumerableMap.at(burnableShares, i);
            strategies[i] = strategy;
            shares[i] = shareAmount;
        }

        return (strategies, shares);
    }

    /// @inheritdoc IStrategyManager
    function getPendingOperatorSets() external view returns (OperatorSet[] memory) {
        uint256 totalEntries = _pendingOperatorSets.length();
        OperatorSet[] memory operatorSets = new OperatorSet[](totalEntries);
        for (uint256 i = 0; i < totalEntries; i++) {
            operatorSets[i] = _pendingOperatorSets.at(i).decode();
        }
        return operatorSets;
    }

    /// @inheritdoc IStrategyManager
    function getPendingSlashIds(
        OperatorSet calldata operatorSet
    ) external view returns (uint256[] memory) {
        return _pendingSlashIds[operatorSet.key()].values();
    }

    /// @inheritdoc IStrategyManager
    function getSlashResolutionBlock(
        OperatorSet calldata operatorSet,
        uint256 slashId
    ) external view returns (uint32) {
        return _slashResolutionBlock[operatorSet.key()][slashId];
    }
}
