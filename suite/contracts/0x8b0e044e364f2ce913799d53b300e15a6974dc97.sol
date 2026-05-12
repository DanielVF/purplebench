// SPDX--License-Identifier: MIT
/* pragma solidity >=0.8.0; */

interface IEulerSwap {
    /// @dev Constant pool parameters, loaded from trailing calldata.
    struct StaticParams {
        address supplyVault0;
        address supplyVault1;
        address borrowVault0;
        address borrowVault1;
        address eulerAccount;
        address feeRecipient;
    }

    /// @dev Reconfigurable pool parameters, loaded from storage.
    struct DynamicParams {
        uint112 equilibriumReserve0;
        uint112 equilibriumReserve1;
        uint112 minReserve0;
        uint112 minReserve1;
        uint80 priceX;
        uint80 priceY;
        uint64 concentrationX;
        uint64 concentrationY;
        uint64 fee0;
        uint64 fee1;
        uint40 expiration;
        uint8 swapHookedOperations;
        address swapHook;
    }

    /// @dev Starting configuration of pool storage.
    struct InitialState {
        uint112 reserve0;
        uint112 reserve1;
    }

    /// @notice Performs initial activation setup, such as approving vaults to access the
    /// EulerSwap instance's tokens, enabling vaults as collateral, setting up Uniswap
    /// hooks, etc. This should only be invoked by the factory.
    function activate(DynamicParams calldata dynamicParams, InitialState calldata initialState) external;

    /// @notice Installs or uninstalls a manager. Managers can reconfigure the dynamic EulerSwap parameters.
    /// Only callable by the owner (eulerAccount).
    /// @param manager Address to install/uninstall
    /// @param installed Whether the manager should be installed or uninstalled
    function setManager(address manager, bool installed) external;

    /// @notice Addresses configured as managers. Managers can reconfigure the pool parameters.
    /// @param manager Address to check
    /// @return installed Whether the address is currently a manager of this pool
    function managers(address manager) external view returns (bool installed);

    /// @notice Reconfigured the pool's parameters. Only callable by the owner (eulerAccount)
    /// or a manager.
    function reconfigure(DynamicParams calldata dParams, InitialState calldata initialState) external;

    /// @notice Retrieves the pool's static parameters.
    function getStaticParams() external view returns (StaticParams memory);

    /// @notice Retrieves the pool's dynamic parameters.
    function getDynamicParams() external view returns (DynamicParams memory);

    /// @notice Retrieves the underlying assets supported by this pool.
    function getAssets() external view returns (address asset0, address asset1);

    /// @notice Retrieves the current reserves from storage, along with the pool's lock status.
    /// @return reserve0 The amount of asset0 in the pool
    /// @return reserve1 The amount of asset1 in the pool
    /// @return status The status of the pool (0 = unactivated, 1 = unlocked, 2 = locked)
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 status);

    /// @notice Whether or not this EulerSwap instance is installed as an operator of
    /// the eulerAccount in the EVC.
    function isInstalled() external view returns (bool installed);

    /// @notice Generates a quote for how much a given size swap will cost.
    /// @param tokenIn The input token that the swapper SENDS
    /// @param tokenOut The output token that the swapper GETS
    /// @param amount The quantity of input or output tokens, for exact input and exact output swaps respectively
    /// @param exactIn True if this is an exact input swap, false if exact output
    /// @return The quoted quantity of output or input tokens, for exact input and exact output swaps respectively
    function computeQuote(address tokenIn, address tokenOut, uint256 amount, bool exactIn)
        external
        view
        returns (uint256);

    /// @notice Upper-bounds on the amounts of each token that this pool can currently support swaps for.
    /// @return limitIn Max amount of `tokenIn` that can be sold.
    /// @return limitOut Max amount of `tokenOut` that can be bought.
    function getLimits(address tokenIn, address tokenOut) external view returns (uint256 limitIn, uint256 limitOut);

    /// @notice Optimistically sends the requested amounts of tokens to the `to`
    /// address, invokes `eulerSwapCall` callback on `to` (if `data` was provided),
    /// and then verifies that a sufficient amount of tokens were transferred to
    /// satisfy the swapping curve invariant.
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
}
// SPDX--License-Identifier: GPL-2.0-or-later

/* pragma solidity ^0.8.0; */

type EC is uint256;

/// @title ExecutionContext
/// @custom:security-contact security@euler.xyz
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice This library provides functions for managing the execution context in the Ethereum Vault Connector.
/// @dev The execution context is a bit field that stores the following information:
/// @dev - on behalf of account - an account on behalf of which the currently executed operation is being performed
/// @dev - checks deferred flag - used to indicate whether checks are deferred
/// @dev - checks in progress flag - used to indicate that the account/vault status checks are in progress. This flag is
/// used to prevent re-entrancy.
/// @dev - control collateral in progress flag - used to indicate that the control collateral is in progress. This flag
/// is used to prevent re-entrancy.
/// @dev - operator authenticated flag - used to indicate that the currently executed operation is being performed by
/// the account operator
/// @dev - simulation flag - used to indicate that the currently executed batch call is a simulation
/// @dev - stamp - dummy value for optimization purposes
library ExecutionContext {
    uint256 internal constant ON_BEHALF_OF_ACCOUNT_MASK =
        0x000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    uint256 internal constant CHECKS_DEFERRED_MASK = 0x0000000000000000000000FF0000000000000000000000000000000000000000;
    uint256 internal constant CHECKS_IN_PROGRESS_MASK =
        0x00000000000000000000FF000000000000000000000000000000000000000000;
    uint256 internal constant CONTROL_COLLATERAL_IN_PROGRESS_LOCK_MASK =
        0x000000000000000000FF00000000000000000000000000000000000000000000;
    uint256 internal constant OPERATOR_AUTHENTICATED_MASK =
        0x0000000000000000FF0000000000000000000000000000000000000000000000;
    uint256 internal constant SIMULATION_MASK = 0x00000000000000FF000000000000000000000000000000000000000000000000;
    uint256 internal constant STAMP_OFFSET = 200;

    // None of the functions below modifies the state. All the functions operate on the copy
    // of the execution context and return its modified value as a result. In order to update
    // one should use the result of the function call as a new execution context value.

    function getOnBehalfOfAccount(EC self) internal pure returns (address result) {
        result = address(uint160(EC.unwrap(self) & ON_BEHALF_OF_ACCOUNT_MASK));
    }

    function setOnBehalfOfAccount(EC self, address account) internal pure returns (EC result) {
        result = EC.wrap((EC.unwrap(self) & ~ON_BEHALF_OF_ACCOUNT_MASK) | uint160(account));
    }

    function areChecksDeferred(EC self) internal pure returns (bool result) {
        result = EC.unwrap(self) & CHECKS_DEFERRED_MASK != 0;
    }

    function setChecksDeferred(EC self) internal pure returns (EC result) {
        result = EC.wrap(EC.unwrap(self) | CHECKS_DEFERRED_MASK);
    }

    function areChecksInProgress(EC self) internal pure returns (bool result) {
        result = EC.unwrap(self) & CHECKS_IN_PROGRESS_MASK != 0;
    }

    function setChecksInProgress(EC self) internal pure returns (EC result) {
        result = EC.wrap(EC.unwrap(self) | CHECKS_IN_PROGRESS_MASK);
    }

    function isControlCollateralInProgress(EC self) internal pure returns (bool result) {
        result = EC.unwrap(self) & CONTROL_COLLATERAL_IN_PROGRESS_LOCK_MASK != 0;
    }

    function setControlCollateralInProgress(EC self) internal pure returns (EC result) {
        result = EC.wrap(EC.unwrap(self) | CONTROL_COLLATERAL_IN_PROGRESS_LOCK_MASK);
    }

    function isOperatorAuthenticated(EC self) internal pure returns (bool result) {
        result = EC.unwrap(self) & OPERATOR_AUTHENTICATED_MASK != 0;
    }

    function setOperatorAuthenticated(EC self) internal pure returns (EC result) {
        result = EC.wrap(EC.unwrap(self) | OPERATOR_AUTHENTICATED_MASK);
    }

    function clearOperatorAuthenticated(EC self) internal pure returns (EC result) {
        result = EC.wrap(EC.unwrap(self) & ~OPERATOR_AUTHENTICATED_MASK);
    }

    function isSimulationInProgress(EC self) internal pure returns (bool result) {
        result = EC.unwrap(self) & SIMULATION_MASK != 0;
    }

    function setSimulationInProgress(EC self) internal pure returns (EC result) {
        result = EC.wrap(EC.unwrap(self) | SIMULATION_MASK);
    }
}
// SPDX--License-Identifier: GPL-2.0-or-later

/* pragma solidity >=0.8.0; */

/// @title IEVC
/// @custom:security-contact security@euler.xyz
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice This interface defines the methods for the Ethereum Vault Connector.
interface IEVC {
    /// @notice A struct representing a batch item.
    /// @dev Each batch item represents a single operation to be performed within a checks deferred context.
    struct BatchItem {
        /// @notice The target contract to be called.
        address targetContract;
        /// @notice The account on behalf of which the operation is to be performed. msg.sender must be authorized to
        /// act on behalf of this account. Must be address(0) if the target contract is the EVC itself.
        address onBehalfOfAccount;
        /// @notice The amount of value to be forwarded with the call. If the value is type(uint256).max, the whole
        /// balance of the EVC contract will be forwarded. Must be 0 if the target contract is the EVC itself.
        uint256 value;
        /// @notice The encoded data which is called on the target contract.
        bytes data;
    }

    /// @notice A struct representing the result of a batch item operation.
    /// @dev Used only for simulation purposes.
    struct BatchItemResult {
        /// @notice A boolean indicating whether the operation was successful.
        bool success;
        /// @notice The result of the operation.
        bytes result;
    }

    /// @notice A struct representing the result of the account or vault status check.
    /// @dev Used only for simulation purposes.
    struct StatusCheckResult {
        /// @notice The address of the account or vault for which the check was performed.
        address checkedAddress;
        /// @notice A boolean indicating whether the status of the account or vault is valid.
        bool isValid;
        /// @notice The result of the check.
        bytes result;
    }

    /// @notice Returns current raw execution context.
    /// @dev When checks in progress, on behalf of account is always address(0).
    /// @return context Current raw execution context.
    function getRawExecutionContext() external view returns (uint256 context);

    /// @notice Returns an account on behalf of which the operation is being executed at the moment and whether the
    /// controllerToCheck is an enabled controller for that account.
    /// @dev This function should only be used by external smart contracts if msg.sender is the EVC. Otherwise, the
    /// account address returned must not be trusted.
    /// @dev When checks in progress, on behalf of account is always address(0). When address is zero, the function
    /// reverts to protect the consumer from ever relying on the on behalf of account address which is in its default
    /// state.
    /// @param controllerToCheck The address of the controller for which it is checked whether it is an enabled
    /// controller for the account on behalf of which the operation is being executed at the moment.
    /// @return onBehalfOfAccount An account that has been authenticated and on behalf of which the operation is being
    /// executed at the moment.
    /// @return controllerEnabled A boolean value that indicates whether controllerToCheck is an enabled controller for
    /// the account on behalf of which the operation is being executed at the moment. Always false if controllerToCheck
    /// is address(0).
    function getCurrentOnBehalfOfAccount(address controllerToCheck)
        external
        view
        returns (address onBehalfOfAccount, bool controllerEnabled);

    /// @notice Checks if checks are deferred.
    /// @return A boolean indicating whether checks are deferred.
    function areChecksDeferred() external view returns (bool);

    /// @notice Checks if checks are in progress.
    /// @return A boolean indicating whether checks are in progress.
    function areChecksInProgress() external view returns (bool);

    /// @notice Checks if control collateral is in progress.
    /// @return A boolean indicating whether control collateral is in progress.
    function isControlCollateralInProgress() external view returns (bool);

    /// @notice Checks if an operator is authenticated.
    /// @return A boolean indicating whether an operator is authenticated.
    function isOperatorAuthenticated() external view returns (bool);

    /// @notice Checks if a simulation is in progress.
    /// @return A boolean indicating whether a simulation is in progress.
    function isSimulationInProgress() external view returns (bool);

    /// @notice Checks whether the specified account and the other account have the same owner.
    /// @dev The function is used to check whether one account is authorized to perform operations on behalf of the
    /// other. Accounts are considered to have a common owner if they share the first 19 bytes of their address.
    /// @param account The address of the account that is being checked.
    /// @param otherAccount The address of the other account that is being checked.
    /// @return A boolean flag that indicates whether the accounts have the same owner.
    function haveCommonOwner(address account, address otherAccount) external pure returns (bool);

    /// @notice Returns the address prefix of the specified account.
    /// @dev The address prefix is the first 19 bytes of the account address.
    /// @param account The address of the account whose address prefix is being retrieved.
    /// @return A bytes19 value that represents the address prefix of the account.
    function getAddressPrefix(address account) external pure returns (bytes19);

    /// @notice Returns the owner for the specified account.
    /// @dev The function returns address(0) if the owner is not registered. Registration of the owner happens on the
    /// initial
    /// interaction with the EVC that requires authentication of an owner.
    /// @param account The address of the account whose owner is being retrieved.
    /// @return owner The address of the account owner. An account owner is an EOA/smart contract which address matches
    /// the first 19 bytes of the account address.
    function getAccountOwner(address account) external view returns (address);

    /// @notice Checks if lockdown mode is enabled for a given address prefix.
    /// @param addressPrefix The address prefix to check for lockdown mode status.
    /// @return A boolean indicating whether lockdown mode is enabled.
    function isLockdownMode(bytes19 addressPrefix) external view returns (bool);

    /// @notice Checks if permit functionality is disabled for a given address prefix.
    /// @param addressPrefix The address prefix to check for permit functionality status.
    /// @return A boolean indicating whether permit functionality is disabled.
    function isPermitDisabledMode(bytes19 addressPrefix) external view returns (bool);

    /// @notice Returns the current nonce for a given address prefix and nonce namespace.
    /// @dev Each nonce namespace provides 256 bit nonce that has to be used sequentially. There's no requirement to use
    /// all the nonces for a given nonce namespace before moving to the next one which allows to use permit messages in
    /// a non-sequential manner.
    /// @param addressPrefix The address prefix for which the nonce is being retrieved.
    /// @param nonceNamespace The nonce namespace for which the nonce is being retrieved.
    /// @return nonce The current nonce for the given address prefix and nonce namespace.
    function getNonce(bytes19 addressPrefix, uint256 nonceNamespace) external view returns (uint256 nonce);

    /// @notice Returns the bit field for a given address prefix and operator.
    /// @dev The bit field is used to store information about authorized operators for a given address prefix. Each bit
    /// in the bit field corresponds to one account belonging to the same owner. If the bit is set, the operator is
    /// authorized for the account.
    /// @param addressPrefix The address prefix for which the bit field is being retrieved.
    /// @param operator The address of the operator for which the bit field is being retrieved.
    /// @return operatorBitField The bit field for the given address prefix and operator. The bit field defines which
    /// accounts the operator is authorized for. It is a 256-position binary array like 0...010...0, marking the account
    /// positionally in a uint256. The position in the bit field corresponds to the account ID (0-255), where 0 is the
    /// owner account's ID.
    function getOperator(bytes19 addressPrefix, address operator) external view returns (uint256 operatorBitField);

    /// @notice Returns whether a given operator has been authorized for a given account.
    /// @param account The address of the account whose operator is being checked.
    /// @param operator The address of the operator that is being checked.
    /// @return authorized A boolean value that indicates whether the operator is authorized for the account.
    function isAccountOperatorAuthorized(address account, address operator) external view returns (bool authorized);

    /// @notice Enables or disables lockdown mode for a given address prefix.
    /// @dev This function can only be called by the owner of the address prefix. To disable this mode, the EVC
    /// must be called directly. It is not possible to disable this mode by using checks-deferrable call or
    /// permit message.
    /// @param addressPrefix The address prefix for which the lockdown mode is being set.
    /// @param enabled A boolean indicating whether to enable or disable lockdown mode.
    function setLockdownMode(bytes19 addressPrefix, bool enabled) external payable;

    /// @notice Enables or disables permit functionality for a given address prefix.
    /// @dev This function can only be called by the owner of the address prefix. To disable this mode, the EVC
    /// must be called directly. It is not possible to disable this mode by using checks-deferrable call or (by
    /// definition) permit message. To support permit functionality by default, note that the logic was inverted here. To
    /// disable  the permit functionality, one must pass true as the second argument. To enable the permit
    /// functionality, one must pass false as the second argument.
    /// @param addressPrefix The address prefix for which the permit functionality is being set.
    /// @param enabled A boolean indicating whether to enable or disable the disable-permit mode.
    function setPermitDisabledMode(bytes19 addressPrefix, bool enabled) external payable;

    /// @notice Sets the nonce for a given address prefix and nonce namespace.
    /// @dev This function can only be called by the owner of the address prefix. Each nonce namespace provides a 256
    /// bit nonce that has to be used sequentially. There's no requirement to use all the nonces for a given nonce
    /// namespace before moving to the next one which allows the use of permit messages in a non-sequential manner. To
    /// invalidate signed permit messages, set the nonce for a given nonce namespace accordingly. To invalidate all the
    /// permit messages for a given nonce namespace, set the nonce to type(uint).max.
    /// @param addressPrefix The address prefix for which the nonce is being set.
    /// @param nonceNamespace The nonce namespace for which the nonce is being set.
    /// @param nonce The new nonce for the given address prefix and nonce namespace.
    function setNonce(bytes19 addressPrefix, uint256 nonceNamespace, uint256 nonce) external payable;

    /// @notice Sets the bit field for a given address prefix and operator.
    /// @dev This function can only be called by the owner of the address prefix. Each bit in the bit field corresponds
    /// to one account belonging to the same owner. If the bit is set, the operator is authorized for the account.
    /// @param addressPrefix The address prefix for which the bit field is being set.
    /// @param operator The address of the operator for which the bit field is being set. Can neither be the EVC address
    /// nor an address belonging to the same address prefix.
    /// @param operatorBitField The new bit field for the given address prefix and operator. Reverts if the provided
    /// value is equal to the currently stored value.
    function setOperator(bytes19 addressPrefix, address operator, uint256 operatorBitField) external payable;

    /// @notice Authorizes or deauthorizes an operator for the account.
    /// @dev Only the owner or authorized operator of the account can call this function. An operator is an address that
    /// can perform actions for an account on behalf of the owner. If it's an operator calling this function, it can
    /// only deauthorize itself.
    /// @param account The address of the account whose operator is being set or unset.
    /// @param operator The address of the operator that is being installed or uninstalled. Can neither be the EVC
    /// address nor an address belonging to the same owner as the account.
    /// @param authorized A boolean value that indicates whether the operator is being authorized or deauthorized.
    /// Reverts if the provided value is equal to the currently stored value.
    function setAccountOperator(address account, address operator, bool authorized) external payable;

    /// @notice Returns an array of collaterals enabled for an account.
    /// @dev A collateral is a vault for which an account's balances are under the control of the currently enabled
    /// controller vault.
    /// @param account The address of the account whose collaterals are being queried.
    /// @return An array of addresses that are enabled collaterals for the account.
    function getCollaterals(address account) external view returns (address[] memory);

    /// @notice Returns whether a collateral is enabled for an account.
    /// @dev A collateral is a vault for which account's balances are under the control of the currently enabled
    /// controller vault.
    /// @param account The address of the account that is being checked.
    /// @param vault The address of the collateral that is being checked.
    /// @return A boolean value that indicates whether the vault is an enabled collateral for the account or not.
    function isCollateralEnabled(address account, address vault) external view returns (bool);

    /// @notice Enables a collateral for an account.
    /// @dev A collaterals is a vault for which account's balances are under the control of the currently enabled
    /// controller vault. Only the owner or an operator of the account can call this function. Unless it's a duplicate,
    /// the collateral is added to the end of the array. There can be at most 10 unique collaterals enabled at a time.
    /// Account status checks are performed.
    /// @param account The account address for which the collateral is being enabled.
    /// @param vault The address being enabled as a collateral.
    function enableCollateral(address account, address vault) external payable;

    /// @notice Disables a collateral for an account.
    /// @dev This function does not preserve the order of collaterals in the array obtained using the getCollaterals
    /// function; the order may change. A collateral is a vault for which account’s balances are under the control of
    /// the currently enabled controller vault. Only the owner or an operator of the account can call this function.
    /// Disabling a collateral might change the order of collaterals in the array obtained using getCollaterals
    /// function. Account status checks are performed.
    /// @param account The account address for which the collateral is being disabled.
    /// @param vault The address of a collateral being disabled.
    function disableCollateral(address account, address vault) external payable;

    /// @notice Swaps the position of two collaterals so that they appear switched in the array of collaterals for a
    /// given account obtained by calling getCollaterals function.
    /// @dev A collateral is a vault for which account’s balances are under the control of the currently enabled
    /// controller vault. Only the owner or an operator of the account can call this function. The order of collaterals
    /// can be changed by specifying the indices of the two collaterals to be swapped. Indices are zero-based and must
    /// be in the range of 0 to the number of collaterals minus 1. index1 must be lower than index2. Account status
    /// checks are performed.
    /// @param account The address of the account for which the collaterals are being reordered.
    /// @param index1 The index of the first collateral to be swapped.
    /// @param index2 The index of the second collateral to be swapped.
    function reorderCollaterals(address account, uint8 index1, uint8 index2) external payable;

    /// @notice Returns an array of enabled controllers for an account.
    /// @dev A controller is a vault that has been chosen for an account to have special control over the account's
    /// balances in enabled collaterals vaults. A user can have multiple controllers during a call execution, but at
    /// most one can be selected when the account status check is performed.
    /// @param account The address of the account whose controllers are being queried.
    /// @return An array of addresses that are the enabled controllers for the account.
    function getControllers(address account) external view returns (address[] memory);

    /// @notice Returns whether a controller is enabled for an account.
    /// @dev A controller is a vault that has been chosen for an account to have special control over account’s
    /// balances in the enabled collaterals vaults.
    /// @param account The address of the account that is being checked.
    /// @param vault The address of the controller that is being checked.
    /// @return A boolean value that indicates whether the vault is enabled controller for the account or not.
    function isControllerEnabled(address account, address vault) external view returns (bool);

    /// @notice Enables a controller for an account.
    /// @dev A controller is a vault that has been chosen for an account to have special control over account’s
    /// balances in the enabled collaterals vaults. Only the owner or an operator of the account can call this function.
    /// Unless it's a duplicate, the controller is added to the end of the array. Transiently, there can be at most 10
    /// unique controllers enabled at a time, but at most one can be enabled after the outermost checks-deferrable
    /// call concludes. Account status checks are performed.
    /// @param account The address for which the controller is being enabled.
    /// @param vault The address of the controller being enabled.
    function enableController(address account, address vault) external payable;

    /// @notice Disables a controller for an account.
    /// @dev A controller is a vault that has been chosen for an account to have special control over account’s
    /// balances in the enabled collaterals vaults. Only the vault itself can call this function. Disabling a controller
    /// might change the order of controllers in the array obtained using getControllers function. Account status checks
    /// are performed.
    /// @param account The address for which the calling controller is being disabled.
    function disableController(address account) external payable;

    /// @notice Executes signed arbitrary data by self-calling into the EVC.
    /// @dev Low-level call function is used to execute the arbitrary data signed by the owner or the operator on the
    /// EVC contract. During that call, EVC becomes msg.sender.
    /// @param signer The address signing the permit message (ECDSA) or verifying the permit message signature
    /// (ERC-1271). It's also the owner or the operator of all the accounts for which authentication will be needed
    /// during the execution of the arbitrary data call.
    /// @param sender The address of the msg.sender which is expected to execute the data signed by the signer. If
    /// address(0) is passed, the msg.sender is ignored.
    /// @param nonceNamespace The nonce namespace for which the nonce is being used.
    /// @param nonce The nonce for the given account and nonce namespace. A valid nonce value is considered to be the
    /// value currently stored and can take any value between 0 and type(uint256).max - 1.
    /// @param deadline The timestamp after which the permit is considered expired.
    /// @param value The amount of value to be forwarded with the call. If the value is type(uint256).max, the whole
    /// balance of the EVC contract will be forwarded.
    /// @param data The encoded data which is self-called on the EVC contract.
    /// @param signature The signature of the data signed by the signer.
    function permit(
        address signer,
        address sender,
        uint256 nonceNamespace,
        uint256 nonce,
        uint256 deadline,
        uint256 value,
        bytes calldata data,
        bytes calldata signature
    ) external payable;

    /// @notice Calls into a target contract as per data encoded.
    /// @dev This function defers the account and vault status checks (it's a checks-deferrable call). If the outermost
    /// call ends, the account and vault status checks are performed.
    /// @dev This function can be used to interact with any contract while checks are deferred. If the target contract
    /// is msg.sender, msg.sender is called back with the calldata provided and the context set up according to the
    /// account provided. If the target contract is not msg.sender, only the owner or the operator of the account
    /// provided can call this function.
    /// @dev This function can be used to recover the remaining value from the EVC contract.
    /// @param targetContract The address of the contract to be called.
    /// @param onBehalfOfAccount  If the target contract is msg.sender, the address of the account which will be set
    /// in the context. It assumes msg.sender has authenticated the account themselves. If the target contract is
    /// not msg.sender, the address of the account for which it is checked whether msg.sender is authorized to act
    /// on behalf of.
    /// @param value The amount of value to be forwarded with the call. If the value is type(uint256).max, the whole
    /// balance of the EVC contract will be forwarded.
    /// @param data The encoded data which is called on the target contract.
    /// @return result The result of the call.
    function call(
        address targetContract,
        address onBehalfOfAccount,
        uint256 value,
        bytes calldata data
    ) external payable returns (bytes memory result);

    /// @notice For a given account, calls into one of the enabled collateral vaults from the currently enabled
    /// controller vault as per data encoded.
    /// @dev This function defers the account and vault status checks (it's a checks-deferrable call). If the outermost
    /// call ends, the account and vault status checks are performed.
    /// @dev This function can be used to interact with any contract while checks are deferred as long as the contract
    /// is enabled as a collateral of the account and the msg.sender is the only enabled controller of the account.
    /// @param targetCollateral The collateral address to be called.
    /// @param onBehalfOfAccount The address of the account for which it is checked whether msg.sender is authorized to
    /// act on behalf.
    /// @param value The amount of value to be forwarded with the call. If the value is type(uint256).max, the whole
    /// balance of the EVC contract will be forwarded.
    /// @param data The encoded data which is called on the target collateral.
    /// @return result The result of the call.
    function controlCollateral(
        address targetCollateral,
        address onBehalfOfAccount,
        uint256 value,
        bytes calldata data
    ) external payable returns (bytes memory result);

    /// @notice Executes multiple calls into the target contracts while checks deferred as per batch items provided.
    /// @dev This function defers the account and vault status checks (it's a checks-deferrable call). If the outermost
    /// call ends, the account and vault status checks are performed.
    /// @dev The authentication rules for each batch item are the same as for the call function.
    /// @param items An array of batch items to be executed.
    function batch(BatchItem[] calldata items) external payable;

    /// @notice Executes multiple calls into the target contracts while checks deferred as per batch items provided.
    /// @dev This function always reverts as it's only used for simulation purposes. This function cannot be called
    /// within a checks-deferrable call.
    /// @param items An array of batch items to be executed.
    function batchRevert(BatchItem[] calldata items) external payable;

    /// @notice Executes multiple calls into the target contracts while checks deferred as per batch items provided.
    /// @dev This function does not modify state and should only be used for simulation purposes. This function cannot
    /// be called within a checks-deferrable call.
    /// @param items An array of batch items to be executed.
    /// @return batchItemsResult An array of batch item results for each item.
    /// @return accountsStatusCheckResult An array of account status check results for each account.
    /// @return vaultsStatusCheckResult An array of vault status check results for each vault.
    function batchSimulation(BatchItem[] calldata items)
        external
        payable
        returns (
            BatchItemResult[] memory batchItemsResult,
            StatusCheckResult[] memory accountsStatusCheckResult,
            StatusCheckResult[] memory vaultsStatusCheckResult
        );

    /// @notice Retrieves the timestamp of the last successful account status check performed for a specific account.
    /// @dev This function reverts if the checks are in progress.
    /// @dev The account status check is considered to be successful if it calls into the selected controller vault and
    /// obtains expected magic value. This timestamp does not change if the account status is considered valid when no
    /// controller enabled. When consuming, one might need to ensure that the account status check is not deferred at
    /// the moment.
    /// @param account The address of the account for which the last status check timestamp is being queried.
    /// @return The timestamp of the last status check as a uint256.
    function getLastAccountStatusCheckTimestamp(address account) external view returns (uint256);

    /// @notice Checks whether the status check is deferred for a given account.
    /// @dev This function reverts if the checks are in progress.
    /// @param account The address of the account for which it is checked whether the status check is deferred.
    /// @return A boolean flag that indicates whether the status check is deferred or not.
    function isAccountStatusCheckDeferred(address account) external view returns (bool);

    /// @notice Checks the status of an account and reverts if it is not valid.
    /// @dev If checks deferred, the account is added to the set of accounts to be checked at the end of the outermost
    /// checks-deferrable call. There can be at most 10 unique accounts added to the set at a time. Account status
    /// check is performed by calling into the selected controller vault and passing the array of currently enabled
    /// collaterals. If controller is not selected, the account is always considered valid.
    /// @param account The address of the account to be checked.
    function requireAccountStatusCheck(address account) external payable;

    /// @notice Forgives previously deferred account status check.
    /// @dev Account address is removed from the set of addresses for which status checks are deferred. This function
    /// can only be called by the currently enabled controller of a given account. Depending on the vault
    /// implementation, may be needed in the liquidation flow.
    /// @param account The address of the account for which the status check is forgiven.
    function forgiveAccountStatusCheck(address account) external payable;

    /// @notice Checks whether the status check is deferred for a given vault.
    /// @dev This function reverts if the checks are in progress.
    /// @param vault The address of the vault for which it is checked whether the status check is deferred.
    /// @return A boolean flag that indicates whether the status check is deferred or not.
    function isVaultStatusCheckDeferred(address vault) external view returns (bool);

    /// @notice Checks the status of a vault and reverts if it is not valid.
    /// @dev If checks deferred, the vault is added to the set of vaults to be checked at the end of the outermost
    /// checks-deferrable call. There can be at most 10 unique vaults added to the set at a time. This function can
    /// only be called by the vault itself.
    function requireVaultStatusCheck() external payable;

    /// @notice Forgives previously deferred vault status check.
    /// @dev Vault address is removed from the set of addresses for which status checks are deferred. This function can
    /// only be called by the vault itself.
    function forgiveVaultStatusCheck() external payable;

    /// @notice Checks the status of an account and a vault and reverts if it is not valid.
    /// @dev If checks deferred, the account and the vault are added to the respective sets of accounts and vaults to be
    /// checked at the end of the outermost checks-deferrable call. Account status check is performed by calling into
    /// selected controller vault and passing the array of currently enabled collaterals. If controller is not selected,
    /// the account is always considered valid. This function can only be called by the vault itself.
    /// @param account The address of the account to be checked.
    function requireAccountAndVaultStatusCheck(address account) external payable;
}
// SPDX--License-Identifier: MIT

/* pragma solidity ^0.8.0; */
/* import {IEVC} from "../interfaces/IEthereumVaultConnector.sol"; */
/* import {ExecutionContext, EC} from "../ExecutionContext.sol"; */

/// @title EVCUtil
/// @custom:security-contact security@euler.xyz
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice This contract is an abstract base contract for interacting with the Ethereum Vault Connector (EVC).
/// It provides utility functions for authenticating the callers in the context of the EVC, a pattern for enforcing the
/// contracts to be called through the EVC.
abstract contract EVCUtil {
    using ExecutionContext for EC;

    uint160 internal constant ACCOUNT_ID_OFFSET = 8;
    IEVC internal immutable evc;

    error EVC_InvalidAddress();
    error NotAuthorized();
    error ControllerDisabled();

    constructor(address _evc) {
        if (_evc == address(0)) revert EVC_InvalidAddress();

        evc = IEVC(_evc);
    }

    /// @notice Returns the address of the Ethereum Vault Connector (EVC) used by this contract.
    /// @return The address of the EVC contract.
    function EVC() external view virtual returns (address) {
        return address(evc);
    }

    /// @notice Ensures that the msg.sender is the EVC by using the EVC callback functionality if necessary.
    /// @dev Optional to use for functions requiring account and vault status checks to enforce predictable behavior.
    /// @dev If this modifier used in conjuction with any other modifier, it must appear as the first (outermost)
    /// modifier of the function.
    modifier callThroughEVC() virtual {
        _callThroughEVC();
        _;
    }

    /// @notice Ensures that the caller is the EVC in the appropriate context.
    /// @dev Should be used for checkAccountStatus and checkVaultStatus functions.
    modifier onlyEVCWithChecksInProgress() virtual {
        _onlyEVCWithChecksInProgress();
        _;
    }

    /// @notice Ensures a standard authentication path on the EVC allowing the account owner or any of its EVC accounts.
    /// @dev This modifier checks if the caller is the EVC and if so, verifies the execution context.
    /// It reverts if the operator is authenticated, control collateral is in progress, or checks are in progress.
    /// @dev This modifier must not be used on functions utilized by liquidation flows, i.e. transfer or withdraw.
    /// @dev This modifier must not be used on checkAccountStatus and checkVaultStatus functions.
    /// @dev This modifier can be used on access controlled functions to prevent non-standard authentication paths on
    /// the EVC.
    modifier onlyEVCAccount() virtual {
        _authenticateCallerWithStandardContextState(false);
        _;
    }

    /// @notice Ensures a standard authentication path on the EVC.
    /// @dev This modifier checks if the caller is the EVC and if so, verifies the execution context.
    /// It reverts if the operator is authenticated, control collateral is in progress, or checks are in progress.
    /// It reverts if the authenticated account owner is known and it is not the account owner.
    /// @dev It assumes that if the caller is not the EVC, the caller is the account owner.
    /// @dev This modifier must not be used on functions utilized by liquidation flows, i.e. transfer or withdraw.
    /// @dev This modifier must not be used on checkAccountStatus and checkVaultStatus functions.
    /// @dev This modifier can be used on access controlled functions to prevent non-standard authentication paths on
    /// the EVC.
    modifier onlyEVCAccountOwner() virtual {
        _authenticateCallerWithStandardContextState(true);
        _;
    }

    /// @notice Checks whether the specified account and the other account have the same owner.
    /// @dev The function is used to check whether one account is authorized to perform operations on behalf of the
    /// other. Accounts are considered to have a common owner if they share the first 19 bytes of their address.
    /// @param account The address of the account that is being checked.
    /// @param otherAccount The address of the other account that is being checked.
    /// @return A boolean flag that indicates whether the accounts have the same owner.
    function _haveCommonOwner(address account, address otherAccount) internal pure returns (bool) {
        bool result;
        assembly {
            result := lt(xor(account, otherAccount), 0x100)
        }
        return result;
    }

    /// @notice Returns the address prefix of the specified account.
    /// @dev The address prefix is the first 19 bytes of the account address.
    /// @param account The address of the account whose address prefix is being retrieved.
    /// @return A bytes19 value that represents the address prefix of the account.
    function _getAddressPrefix(address account) internal pure returns (bytes19) {
        return bytes19(uint152(uint160(account) >> ACCOUNT_ID_OFFSET));
    }

    /// @notice Retrieves the message sender in the context of the EVC.
    /// @dev This function returns the account on behalf of which the current operation is being performed, which is
    /// either msg.sender or the account authenticated by the EVC.
    /// @return The address of the message sender.
    function _msgSender() internal view virtual returns (address) {
        address sender = msg.sender;

        if (sender == address(evc)) {
            (sender,) = evc.getCurrentOnBehalfOfAccount(address(0));
        }

        return sender;
    }

    /// @notice Retrieves the message sender in the context of the EVC for a borrow operation.
    /// @dev This function returns the account on behalf of which the current operation is being performed, which is
    /// either msg.sender or the account authenticated by the EVC. This function reverts if this contract is not enabled
    /// as a controller for the account on behalf of which the operation is being executed.
    /// @return The address of the message sender.
    function _msgSenderForBorrow() internal view virtual returns (address) {
        address sender = msg.sender;
        bool controllerEnabled;

        if (sender == address(evc)) {
            (sender, controllerEnabled) = evc.getCurrentOnBehalfOfAccount(address(this));
        } else {
            controllerEnabled = evc.isControllerEnabled(sender, address(this));
        }

        if (!controllerEnabled) {
            revert ControllerDisabled();
        }

        return sender;
    }

    /// @notice Retrieves the message sender, ensuring it's any EVC account meaning that the execution context is in a
    /// standard state (not operator authenticated, not control collateral in progress, not checks in progress).
    /// @dev This function must not be used on functions utilized by liquidation flows, i.e. transfer or withdraw.
    /// @dev This function must not be used on checkAccountStatus and checkVaultStatus functions.
    /// @dev This function can be used on access controlled functions to prevent non-standard authentication paths on
    /// the EVC.
    /// @return The address of the message sender.
    function _msgSenderOnlyEVCAccount() internal view returns (address) {
        return _authenticateCallerWithStandardContextState(false);
    }

    /// @notice Retrieves the message sender, ensuring it's the EVC account owner and that the execution context is in a
    /// standard state (not operator authenticated, not control collateral in progress, not checks in progress).
    /// @dev It assumes that if the caller is not the EVC, the caller is the account owner.
    /// @dev This function must not be used on functions utilized by liquidation flows, i.e. transfer or withdraw.
    /// @dev This function must not be used on checkAccountStatus and checkVaultStatus functions.
    /// @dev This function can be used on access controlled functions to prevent non-standard authentication paths on
    /// the EVC.
    /// @return The address of the message sender.
    function _msgSenderOnlyEVCAccountOwner() internal view returns (address) {
        return _authenticateCallerWithStandardContextState(true);
    }

    /// @notice Calls the current external function through the EVC.
    /// @dev This function is used to route the current call through the EVC if it's not already coming from the EVC. It
    /// makes the EVC set the execution context and call back this contract with unchanged calldata. msg.sender is used
    /// as the onBehalfOfAccount.
    /// @dev This function shall only be used by the callThroughEVC modifier.
    function _callThroughEVC() internal {
        address _evc = address(evc);
        if (msg.sender == _evc) return;

        assembly {
            mstore(0, 0x1f8b521500000000000000000000000000000000000000000000000000000000) // EVC.call selector
            mstore(4, address()) // EVC.call 1st argument - address(this)
            mstore(36, caller()) // EVC.call 2nd argument - msg.sender
            mstore(68, callvalue()) // EVC.call 3rd argument - msg.value
            mstore(100, 128) // EVC.call 4th argument - msg.data, offset to the start of encoding - 128 bytes
            mstore(132, calldatasize()) // msg.data length
            calldatacopy(164, 0, calldatasize()) // original calldata

            // abi encoded bytes array should be zero padded so its length is a multiple of 32
            // store zero word after msg.data bytes and round up calldatasize to nearest multiple of 32
            mstore(add(164, calldatasize()), 0)
            let result := call(gas(), _evc, callvalue(), 0, add(164, and(add(calldatasize(), 31), not(31))), 0, 0)

            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(64, sub(returndatasize(), 64)) } // strip bytes encoding from call return
        }
    }

    /// @notice Ensures that the function is called only by the EVC during the checks phase
    /// @dev Reverts if the caller is not the EVC or if checks are not in progress.
    function _onlyEVCWithChecksInProgress() internal view {
        if (msg.sender != address(evc) || !evc.areChecksInProgress()) {
            revert NotAuthorized();
        }
    }

    /// @notice Ensures that the function is called only by the EVC account owner or any of its EVC accounts
    /// @dev This function checks if the caller is the EVC and if so, verifies that the execution context is not in a
    /// special state (operator authenticated, collateral control in progress, or checks in progress). If
    /// onlyAccountOwner is true and the owner was already registered on the EVC, it verifies that the onBehalfOfAccount
    /// is the owner. If onlyAccountOwner is false, it allows any EVC account of the owner to call the function.
    /// @param onlyAccountOwner If true, only allows the account owner; if false, allows any EVC account of the owner
    /// @return The address of the message sender.
    function _authenticateCallerWithStandardContextState(bool onlyAccountOwner) internal view returns (address) {
        if (msg.sender == address(evc)) {
            EC ec = EC.wrap(evc.getRawExecutionContext());

            if (ec.isOperatorAuthenticated() || ec.isControlCollateralInProgress() || ec.areChecksInProgress()) {
                revert NotAuthorized();
            }

            address onBehalfOfAccount = ec.getOnBehalfOfAccount();

            if (onlyAccountOwner) {
                address owner = evc.getAccountOwner(onBehalfOfAccount);

                if (owner != address(0) && owner != onBehalfOfAccount) {
                    revert NotAuthorized();
                }
            }

            return onBehalfOfAccount;
        }

        return msg.sender;
    }
}
// SPDX--License-Identifier: BUSL-1.1
/* pragma solidity ^0.8.27; */
/* import {IEulerSwap} from "../interfaces/IEulerSwap.sol"; */

library CtxLib {
    struct State {
        uint112 reserve0;
        uint112 reserve1;
        uint32 status; // 0 = unactivated, 1 = unlocked, 2 = locked
        mapping(address manager => bool installed) managers;
    }

    // keccak256("eulerSwap.state") - 1
    bytes32 internal constant CtxStateLocation = 0x10ee9b31f73104ff2cf413742414a498e1f7b56c11cb512bca58a9c50727bb58;

    function getState() internal pure returns (State storage s) {
        assembly {
            s.slot := CtxStateLocation
        }
    }

    // keccak256("eulerSwap.dynamicParams") - 1
    bytes32 internal constant CtxDynamicParamsLocation =
        0xca4da3477ca592c011a91679daaaf19e95f02a3a91537965b17e4113575fb219;

    function writeDynamicParamsToStorage(IEulerSwap.DynamicParams memory dParams) internal {
        IEulerSwap.DynamicParams storage s;

        assembly {
            s.slot := CtxDynamicParamsLocation
        }

        s.equilibriumReserve0 = dParams.equilibriumReserve0;
        s.equilibriumReserve1 = dParams.equilibriumReserve1;
        s.minReserve0 = dParams.minReserve0;
        s.minReserve1 = dParams.minReserve1;
        s.priceX = dParams.priceX;
        s.priceY = dParams.priceY;
        s.concentrationX = dParams.concentrationX;
        s.concentrationY = dParams.concentrationY;
        s.fee0 = dParams.fee0;
        s.fee1 = dParams.fee1;
        s.expiration = dParams.expiration;
        s.swapHookedOperations = dParams.swapHookedOperations;
        s.swapHook = dParams.swapHook;
    }

    function getDynamicParams() internal pure returns (IEulerSwap.DynamicParams memory) {
        IEulerSwap.DynamicParams storage s;

        assembly {
            s.slot := CtxDynamicParamsLocation
        }

        return s;
    }

    error InsufficientCalldata();

    /// @dev Unpacks encoded Params from trailing calldata. Loosely based on
    /// the implementation from EIP-3448 (except length is hard-coded).
    /// 192 is the size of the StaticParams struct after ABI encoding.
    function getStaticParams() internal pure returns (IEulerSwap.StaticParams memory p) {
        require(msg.data.length >= 192, InsufficientCalldata());
        unchecked {
            return abi.decode(msg.data[msg.data.length - 192:], (IEulerSwap.StaticParams));
        }
    }
}
// SPDX--License-Identifier: BUSL-1.1
/* pragma solidity ^0.8.27; */
/* import {EVCUtil} from "evc/utils/EVCUtil.sol"; */
/* import {CtxLib} from "./libraries/CtxLib.sol"; */

abstract contract EulerSwapBase is EVCUtil {
    error Locked();

    constructor(address evc_) EVCUtil(evc_) {
        CtxLib.State storage s = CtxLib.getState();
        s.status = 2; // can only be used via delegatecall proxy
    }

    modifier nonReentrant() {
        CtxLib.State storage s = CtxLib.getState();
        require(s.status == 1, Locked());
        s.status = 2;

        _;

        s.status = 1;
    }

    modifier nonReentrantView() {
        CtxLib.State storage s = CtxLib.getState();
        require(s.status != 2, Locked());

        _;
    }
}
// SPDX--License-Identifier: MIT
/* pragma solidity ^0.8.0; */
/* import {Currency} from "./Currency.sol"; */
/* import {IHooks} from "../interfaces/IHooks.sol"; */
/* import {PoolIdLibrary} from "./PoolId.sol"; */

using PoolIdLibrary for PoolKey global;

/// @notice Returns the key for identifying a pool
struct PoolKey {
    /// @notice The lower currency of the pool, sorted numerically
    Currency currency0;
    /// @notice The higher currency of the pool, sorted numerically
    Currency currency1;
    /// @notice The pool LP fee, capped at 1_000_000. If the highest bit is 1, the pool has a dynamic fee and must be exactly equal to 0x800000
    uint24 fee;
    /// @notice Ticks that involve positions must be a multiple of tick spacing
    int24 tickSpacing;
    /// @notice The hooks of the pool
    IHooks hooks;
}
// SPDX--License-Identifier: MIT
/* pragma solidity ^0.8.0; */
/* import {Currency} from "../types/Currency.sol"; */
/* import {PoolId} from "../types/PoolId.sol"; */
/* import {PoolKey} from "../types/PoolKey.sol"; */

/// @notice Interface for all protocol-fee related functions in the pool manager
interface IProtocolFees {
    /// @notice Thrown when protocol fee is set too high
    error ProtocolFeeTooLarge(uint24 fee);

    /// @notice Thrown when collectProtocolFees or setProtocolFee is not called by the controller.
    error InvalidCaller();

    /// @notice Thrown when collectProtocolFees is attempted on a token that is synced.
    error ProtocolFeeCurrencySynced();

    /// @notice Emitted when the protocol fee controller address is updated in setProtocolFeeController.
    event ProtocolFeeControllerUpdated(address indexed protocolFeeController);

    /// @notice Emitted when the protocol fee is updated for a pool.
    event ProtocolFeeUpdated(PoolId indexed id, uint24 protocolFee);

    /// @notice Given a currency address, returns the protocol fees accrued in that currency
    /// @param currency The currency to check
    /// @return amount The amount of protocol fees accrued in the currency
    function protocolFeesAccrued(Currency currency) external view returns (uint256 amount);

    /// @notice Sets the protocol fee for the given pool
    /// @param key The key of the pool to set a protocol fee for
    /// @param newProtocolFee The fee to set
    function setProtocolFee(PoolKey memory key, uint24 newProtocolFee) external;

    /// @notice Sets the protocol fee controller
    /// @param controller The new protocol fee controller
    function setProtocolFeeController(address controller) external;

    /// @notice Collects the protocol fees for a given recipient and currency, returning the amount collected
    /// @dev This will revert if the contract is unlocked
    /// @param recipient The address to receive the protocol fees
    /// @param currency The currency to withdraw
    /// @param amount The amount of currency to withdraw
    /// @return amountCollected The amount of currency successfully withdrawn
    function collectProtocolFees(address recipient, Currency currency, uint256 amount)
        external
        returns (uint256 amountCollected);

    /// @notice Returns the current protocol fee controller address
    /// @return address The current protocol fee controller address
    function protocolFeeController() external view returns (address);
}
// SPDX--License-Identifier: MIT
/* pragma solidity ^0.8.0; */

/// @notice Interface for claims over a contract balance, wrapped as a ERC6909
interface IERC6909Claims {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OperatorSet(address indexed owner, address indexed operator, bool approved);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id, uint256 amount);

    event Transfer(address caller, address indexed from, address indexed to, uint256 indexed id, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                 FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Owner balance of an id.
    /// @param owner The address of the owner.
    /// @param id The id of the token.
    /// @return amount The balance of the token.
    function balanceOf(address owner, uint256 id) external view returns (uint256 amount);

    /// @notice Spender allowance of an id.
    /// @param owner The address of the owner.
    /// @param spender The address of the spender.
    /// @param id The id of the token.
    /// @return amount The allowance of the token.
    function allowance(address owner, address spender, uint256 id) external view returns (uint256 amount);

    /// @notice Checks if a spender is approved by an owner as an operator
    /// @param owner The address of the owner.
    /// @param spender The address of the spender.
    /// @return approved The approval status.
    function isOperator(address owner, address spender) external view returns (bool approved);

    /// @notice Transfers an amount of an id from the caller to a receiver.
    /// @param receiver The address of the receiver.
    /// @param id The id of the token.
    /// @param amount The amount of the token.
    /// @return bool True, always, unless the function reverts
    function transfer(address receiver, uint256 id, uint256 amount) external returns (bool);

    /// @notice Transfers an amount of an id from a sender to a receiver.
    /// @param sender The address of the sender.
    /// @param receiver The address of the receiver.
    /// @param id The id of the token.
    /// @param amount The amount of the token.
    /// @return bool True, always, unless the function reverts
    function transferFrom(address sender, address receiver, uint256 id, uint256 amount) external returns (bool);

    /// @notice Approves an amount of an id to a spender.
    /// @param spender The address of the spender.
    /// @param id The id of the token.
    /// @param amount The amount of the token.
    /// @return bool True, always
    function approve(address spender, uint256 id, uint256 amount) external returns (bool);

    /// @notice Sets or removes an operator for the caller.
    /// @param operator The address of the operator.
    /// @param approved The approval status.
    /// @return bool True, always
    function setOperator(address operator, bool approved) external returns (bool);
}
// SPDX--License-Identifier: MIT
/* pragma solidity ^0.8.0; */

/// @notice Interface for functions to access any storage slot in a contract
interface IExtsload {
    /// @notice Called by external contracts to access granular pool state
    /// @param slot Key of slot to sload
    /// @return value The value of the slot as bytes32
    function extsload(bytes32 slot) external view returns (bytes32 value);

    /// @notice Called by external contracts to access granular pool state
    /// @param startSlot Key of slot to start sloading from
    /// @param nSlots Number of slots to load into return value
    /// @return values List of loaded values.
    function extsload(bytes32 startSlot, uint256 nSlots) external view returns (bytes32[] memory values);

    /// @notice Called by external contracts to access sparse pool state
    /// @param slots List of slots to SLOAD from.
    /// @return values List of loaded values.
    function extsload(bytes32[] calldata slots) external view returns (bytes32[] memory values);
}
// SPDX--License-Identifier: MIT
/* pragma solidity ^0.8.24; */

/// @notice Interface for functions to access any transient storage slot in a contract
interface IExttload {
    /// @notice Called by external contracts to access transient storage of the contract
    /// @param slot Key of slot to tload
    /// @return value The value of the slot as bytes32
    function exttload(bytes32 slot) external view returns (bytes32 value);

    /// @notice Called by external contracts to access sparse transient pool state
    /// @param slots List of slots to tload
    /// @return values List of loaded values
    function exttload(bytes32[] calldata slots) external view returns (bytes32[] memory values);
}
// SPDX--License-Identifier: MIT
/* pragma solidity ^0.8.24; */
/* import {Currency} from "../types/Currency.sol"; */
/* import {PoolKey} from "../types/PoolKey.sol"; */
/* import {IHooks} from "./IHooks.sol"; */
/* import {IERC6909Claims} from "./external/IERC6909Claims.sol"; */
/* import {IProtocolFees} from "./IProtocolFees.sol"; */
/* import {BalanceDelta} from "../types/BalanceDelta.sol"; */
/* import {PoolId} from "../types/PoolId.sol"; */
/* import {IExtsload} from "./IExtsload.sol"; */
/* import {IExttload} from "./IExttload.sol"; */

/// @notice Interface for the PoolManager
interface IPoolManager is IProtocolFees, IERC6909Claims, IExtsload, IExttload {
    /// @notice Thrown when a currency is not netted out after the contract is unlocked
    error CurrencyNotSettled();

    /// @notice Thrown when trying to interact with a non-initialized pool
    error PoolNotInitialized();

    /// @notice Thrown when unlock is called, but the contract is already unlocked
    error AlreadyUnlocked();

    /// @notice Thrown when a function is called that requires the contract to be unlocked, but it is not
    error ManagerLocked();

    /// @notice Pools are limited to type(int16).max tickSpacing in #initialize, to prevent overflow
    error TickSpacingTooLarge(int24 tickSpacing);

    /// @notice Pools must have a positive non-zero tickSpacing passed to #initialize
    error TickSpacingTooSmall(int24 tickSpacing);

    /// @notice PoolKey must have currencies where address(currency0) < address(currency1)
    error CurrenciesOutOfOrderOrEqual(address currency0, address currency1);

    /// @notice Thrown when a call to updateDynamicLPFee is made by an address that is not the hook,
    /// or on a pool that does not have a dynamic swap fee.
    error UnauthorizedDynamicLPFeeUpdate();

    /// @notice Thrown when trying to swap amount of 0
    error SwapAmountCannotBeZero();

    ///@notice Thrown when native currency is passed to a non native settlement
    error NonzeroNativeValue();

    /// @notice Thrown when `clear` is called with an amount that is not exactly equal to the open currency delta.
    error MustClearExactPositiveDelta();

    /// @notice Emitted when a new pool is initialized
    /// @param id The abi encoded hash of the pool key struct for the new pool
    /// @param currency0 The first currency of the pool by address sort order
    /// @param currency1 The second currency of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param hooks The hooks contract address for the pool, or address(0) if none
    /// @param sqrtPriceX96 The price of the pool on initialization
    /// @param tick The initial tick of the pool corresponding to the initialized price
    event Initialize(
        PoolId indexed id,
        Currency indexed currency0,
        Currency indexed currency1,
        uint24 fee,
        int24 tickSpacing,
        IHooks hooks,
        uint160 sqrtPriceX96,
        int24 tick
    );

    /// @notice Emitted when a liquidity position is modified
    /// @param id The abi encoded hash of the pool key struct for the pool that was modified
    /// @param sender The address that modified the pool
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param liquidityDelta The amount of liquidity that was added or removed
    /// @param salt The extra data to make positions unique
    event ModifyLiquidity(
        PoolId indexed id, address indexed sender, int24 tickLower, int24 tickUpper, int256 liquidityDelta, bytes32 salt
    );

    /// @notice Emitted for swaps between currency0 and currency1
    /// @param id The abi encoded hash of the pool key struct for the pool that was modified
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param amount0 The delta of the currency0 balance of the pool
    /// @param amount1 The delta of the currency1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of the price of the pool after the swap
    /// @param fee The swap fee in hundredths of a bip
    event Swap(
        PoolId indexed id,
        address indexed sender,
        int128 amount0,
        int128 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick,
        uint24 fee
    );

    /// @notice Emitted for donations
    /// @param id The abi encoded hash of the pool key struct for the pool that was donated to
    /// @param sender The address that initiated the donate call
    /// @param amount0 The amount donated in currency0
    /// @param amount1 The amount donated in currency1
    event Donate(PoolId indexed id, address indexed sender, uint256 amount0, uint256 amount1);

    /// @notice All interactions on the contract that account deltas require unlocking. A caller that calls `unlock` must implement
    /// `IUnlockCallback(msg.sender).unlockCallback(data)`, where they interact with the remaining functions on this contract.
    /// @dev The only functions callable without an unlocking are `initialize` and `updateDynamicLPFee`
    /// @param data Any data to pass to the callback, via `IUnlockCallback(msg.sender).unlockCallback(data)`
    /// @return The data returned by the call to `IUnlockCallback(msg.sender).unlockCallback(data)`
    function unlock(bytes calldata data) external returns (bytes memory);

    /// @notice Initialize the state for a given pool ID
    /// @dev A swap fee totaling MAX_SWAP_FEE (100%) makes exact output swaps impossible since the input is entirely consumed by the fee
    /// @param key The pool key for the pool to initialize
    /// @param sqrtPriceX96 The initial square root price
    /// @return tick The initial tick of the pool
    function initialize(PoolKey memory key, uint160 sqrtPriceX96) external returns (int24 tick);

    struct ModifyLiquidityParams {
        // the lower and upper tick of the position
        int24 tickLower;
        int24 tickUpper;
        // how to modify the liquidity
        int256 liquidityDelta;
        // a value to set if you want unique liquidity positions at the same range
        bytes32 salt;
    }

    /// @notice Modify the liquidity for the given pool
    /// @dev Poke by calling with a zero liquidityDelta
    /// @param key The pool to modify liquidity in
    /// @param params The parameters for modifying the liquidity
    /// @param hookData The data to pass through to the add/removeLiquidity hooks
    /// @return callerDelta The balance delta of the caller of modifyLiquidity. This is the total of both principal, fee deltas, and hook deltas if applicable
    /// @return feesAccrued The balance delta of the fees generated in the liquidity range. Returned for informational purposes
    function modifyLiquidity(PoolKey memory key, ModifyLiquidityParams memory params, bytes calldata hookData)
        external
        returns (BalanceDelta callerDelta, BalanceDelta feesAccrued);

    struct SwapParams {
        /// Whether to swap token0 for token1 or vice versa
        bool zeroForOne;
        /// The desired input amount if negative (exactIn), or the desired output amount if positive (exactOut)
        int256 amountSpecified;
        /// The sqrt price at which, if reached, the swap will stop executing
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swap against the given pool
    /// @param key The pool to swap in
    /// @param params The parameters for swapping
    /// @param hookData The data to pass through to the swap hooks
    /// @return swapDelta The balance delta of the address swapping
    /// @dev Swapping on low liquidity pools may cause unexpected swap amounts when liquidity available is less than amountSpecified.
    /// Additionally note that if interacting with hooks that have the BEFORE_SWAP_RETURNS_DELTA_FLAG or AFTER_SWAP_RETURNS_DELTA_FLAG
    /// the hook may alter the swap input/output. Integrators should perform checks on the returned swapDelta.
    function swap(PoolKey memory key, SwapParams memory params, bytes calldata hookData)
        external
        returns (BalanceDelta swapDelta);

    /// @notice Donate the given currency amounts to the in-range liquidity providers of a pool
    /// @dev Calls to donate can be frontrun adding just-in-time liquidity, with the aim of receiving a portion donated funds.
    /// Donors should keep this in mind when designing donation mechanisms.
    /// @dev This function donates to in-range LPs at slot0.tick. In certain edge-cases of the swap algorithm, the `sqrtPrice` of
    /// a pool can be at the lower boundary of tick `n`, but the `slot0.tick` of the pool is already `n - 1`. In this case a call to
    /// `donate` would donate to tick `n - 1` (slot0.tick) not tick `n` (getTickAtSqrtPrice(slot0.sqrtPriceX96)).
    /// Read the comments in `Pool.swap()` for more information about this.
    /// @param key The key of the pool to donate to
    /// @param amount0 The amount of currency0 to donate
    /// @param amount1 The amount of currency1 to donate
    /// @param hookData The data to pass through to the donate hooks
    /// @return BalanceDelta The delta of the caller after the donate
    function donate(PoolKey memory key, uint256 amount0, uint256 amount1, bytes calldata hookData)
        external
        returns (BalanceDelta);

    /// @notice Writes the current ERC20 balance of the specified currency to transient storage
    /// This is used to checkpoint balances for the manager and derive deltas for the caller.
    /// @dev This MUST be called before any ERC20 tokens are sent into the contract, but can be skipped
    /// for native tokens because the amount to settle is determined by the sent value.
    /// However, if an ERC20 token has been synced and not settled, and the caller instead wants to settle
    /// native funds, this function can be called with the native currency to then be able to settle the native currency
    function sync(Currency currency) external;

    /// @notice Called by the user to net out some value owed to the user
    /// @dev Will revert if the requested amount is not available, consider using `mint` instead
    /// @dev Can also be used as a mechanism for free flash loans
    /// @param currency The currency to withdraw from the pool manager
    /// @param to The address to withdraw to
    /// @param amount The amount of currency to withdraw
    function take(Currency currency, address to, uint256 amount) external;

    /// @notice Called by the user to pay what is owed
    /// @return paid The amount of currency settled
    function settle() external payable returns (uint256 paid);

    /// @notice Called by the user to pay on behalf of another address
    /// @param recipient The address to credit for the payment
    /// @return paid The amount of currency settled
    function settleFor(address recipient) external payable returns (uint256 paid);

    /// @notice WARNING - Any currency that is cleared, will be non-retrievable, and locked in the contract permanently.
    /// A call to clear will zero out a positive balance WITHOUT a corresponding transfer.
    /// @dev This could be used to clear a balance that is considered dust.
    /// Additionally, the amount must be the exact positive balance. This is to enforce that the caller is aware of the amount being cleared.
    function clear(Currency currency, uint256 amount) external;

    /// @notice Called by the user to move value into ERC6909 balance
    /// @param to The address to mint the tokens to
    /// @param id The currency address to mint to ERC6909s, as a uint256
    /// @param amount The amount of currency to mint
    /// @dev The id is converted to a uint160 to correspond to a currency address
    /// If the upper 12 bytes are not 0, they will be 0-ed out
    function mint(address to, uint256 id, uint256 amount) external;

    /// @notice Called by the user to move value from ERC6909 balance
    /// @param from The address to burn the tokens from
    /// @param id The currency address to burn from ERC6909s, as a uint256
    /// @param amount The amount of currency to burn
    /// @dev The id is converted to a uint160 to correspond to a currency address
    /// If the upper 12 bytes are not 0, they will be 0-ed out
    function burn(address from, uint256 id, uint256 amount) external;

    /// @notice Updates the pools lp fees for the a pool that has enabled dynamic lp fees.
    /// @dev A swap fee totaling MAX_SWAP_FEE (100%) makes exact output swaps impossible since the input is entirely consumed by the fee
    /// @param key The key of the pool to update dynamic LP fees for
    /// @param newDynamicLPFee The new dynamic pool LP fee
    function updateDynamicLPFee(PoolKey memory key, uint24 newDynamicLPFee) external;
}
// SPDX--License-Identifier: MIT
/* pragma solidity ^0.8.0; */
/* import {PoolKey} from "../types/PoolKey.sol"; */
/* import {BalanceDelta} from "../types/BalanceDelta.sol"; */
/* import {IPoolManager} from "./IPoolManager.sol"; */
/* import {BeforeSwapDelta} from "../types/BeforeSwapDelta.sol"; */

/// @notice V4 decides whether to invoke specific hooks by inspecting the least significant bits
/// of the address that the hooks contract is deployed to.
/// For example, a hooks contract deployed to address: 0x0000000000000000000000000000000000002400
/// has the lowest bits '10 0100 0000 0000' which would cause the 'before initialize' and 'after add liquidity' hooks to be used.
/// See the Hooks library for the full spec.
/// @dev Should only be callable by the v4 PoolManager.
interface IHooks {
    /// @notice The hook called before the state of a pool is initialized
    /// @param sender The initial msg.sender for the initialize call
    /// @param key The key for the pool being initialized
    /// @param sqrtPriceX96 The sqrt(price) of the pool as a Q64.96
    /// @return bytes4 The function selector for the hook
    function beforeInitialize(address sender, PoolKey calldata key, uint160 sqrtPriceX96) external returns (bytes4);

    /// @notice The hook called after the state of a pool is initialized
    /// @param sender The initial msg.sender for the initialize call
    /// @param key The key for the pool being initialized
    /// @param sqrtPriceX96 The sqrt(price) of the pool as a Q64.96
    /// @param tick The current tick after the state of a pool is initialized
    /// @return bytes4 The function selector for the hook
    function afterInitialize(address sender, PoolKey calldata key, uint160 sqrtPriceX96, int24 tick)
        external
        returns (bytes4);

    /// @notice The hook called before liquidity is added
    /// @param sender The initial msg.sender for the add liquidity call
    /// @param key The key for the pool
    /// @param params The parameters for adding liquidity
    /// @param hookData Arbitrary data handed into the PoolManager by the liquidity provider to be passed on to the hook
    /// @return bytes4 The function selector for the hook
    function beforeAddLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external returns (bytes4);

    /// @notice The hook called after liquidity is added
    /// @param sender The initial msg.sender for the add liquidity call
    /// @param key The key for the pool
    /// @param params The parameters for adding liquidity
    /// @param delta The caller's balance delta after adding liquidity; the sum of principal delta, fees accrued, and hook delta
    /// @param feesAccrued The fees accrued since the last time fees were collected from this position
    /// @param hookData Arbitrary data handed into the PoolManager by the liquidity provider to be passed on to the hook
    /// @return bytes4 The function selector for the hook
    /// @return BalanceDelta The hook's delta in token0 and token1. Positive: the hook is owed/took currency, negative: the hook owes/sent currency
    function afterAddLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes calldata hookData
    ) external returns (bytes4, BalanceDelta);

    /// @notice The hook called before liquidity is removed
    /// @param sender The initial msg.sender for the remove liquidity call
    /// @param key The key for the pool
    /// @param params The parameters for removing liquidity
    /// @param hookData Arbitrary data handed into the PoolManager by the liquidity provider to be be passed on to the hook
    /// @return bytes4 The function selector for the hook
    function beforeRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external returns (bytes4);

    /// @notice The hook called after liquidity is removed
    /// @param sender The initial msg.sender for the remove liquidity call
    /// @param key The key for the pool
    /// @param params The parameters for removing liquidity
    /// @param delta The caller's balance delta after removing liquidity; the sum of principal delta, fees accrued, and hook delta
    /// @param feesAccrued The fees accrued since the last time fees were collected from this position
    /// @param hookData Arbitrary data handed into the PoolManager by the liquidity provider to be be passed on to the hook
    /// @return bytes4 The function selector for the hook
    /// @return BalanceDelta The hook's delta in token0 and token1. Positive: the hook is owed/took currency, negative: the hook owes/sent currency
    function afterRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes calldata hookData
    ) external returns (bytes4, BalanceDelta);

    /// @notice The hook called before a swap
    /// @param sender The initial msg.sender for the swap call
    /// @param key The key for the pool
    /// @param params The parameters for the swap
    /// @param hookData Arbitrary data handed into the PoolManager by the swapper to be be passed on to the hook
    /// @return bytes4 The function selector for the hook
    /// @return BeforeSwapDelta The hook's delta in specified and unspecified currencies. Positive: the hook is owed/took currency, negative: the hook owes/sent currency
    /// @return uint24 Optionally override the lp fee, only used if three conditions are met: 1. the Pool has a dynamic fee, 2. the value's 2nd highest bit is set (23rd bit, 0x400000), and 3. the value is less than or equal to the maximum fee (1 million)
    function beforeSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata hookData
    ) external returns (bytes4, BeforeSwapDelta, uint24);

    /// @notice The hook called after a swap
    /// @param sender The initial msg.sender for the swap call
    /// @param key The key for the pool
    /// @param params The parameters for the swap
    /// @param delta The amount owed to the caller (positive) or owed to the pool (negative)
    /// @param hookData Arbitrary data handed into the PoolManager by the swapper to be be passed on to the hook
    /// @return bytes4 The function selector for the hook
    /// @return int128 The hook's delta in unspecified currency. Positive: the hook is owed/took currency, negative: the hook owes/sent currency
    function afterSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external returns (bytes4, int128);

    /// @notice The hook called before donate
    /// @param sender The initial msg.sender for the donate call
    /// @param key The key for the pool
    /// @param amount0 The amount of token0 being donated
    /// @param amount1 The amount of token1 being donated
    /// @param hookData Arbitrary data handed into the PoolManager by the donor to be be passed on to the hook
    /// @return bytes4 The function selector for the hook
    function beforeDonate(
        address sender,
        PoolKey calldata key,
        uint256 amount0,
        uint256 amount1,
        bytes calldata hookData
    ) external returns (bytes4);

    /// @notice The hook called after donate
    /// @param sender The initial msg.sender for the donate call
    /// @param key The key for the pool
    /// @param amount0 The amount of token0 being donated
    /// @param amount1 The amount of token1 being donated
    /// @param hookData Arbitrary data handed into the PoolManager by the donor to be be passed on to the hook
    /// @return bytes4 The function selector for the hook
    function afterDonate(
        address sender,
        PoolKey calldata key,
        uint256 amount0,
        uint256 amount1,
        bytes calldata hookData
    ) external returns (bytes4);
}
// SPDX--License-Identifier: MIT
/* pragma solidity ^0.8.0; */
/* import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol"; */

/// @title IImmutableState
/// @notice Interface for the ImmutableState contract
interface IImmutableState {
    /// @notice The Uniswap v4 PoolManager contract
    function poolManager() external view returns (IPoolManager);
}
// SPDX--License-Identifier: MIT
/* pragma solidity ^0.8.0; */
/* import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol"; */
/* import {IImmutableState} from "../interfaces/IImmutableState.sol"; */

/// @title Immutable State
/// @notice A collection of immutable state variables, commonly used across multiple contracts
contract ImmutableState is IImmutableState {
    /// @inheritdoc IImmutableState
    IPoolManager public immutable poolManager;

    /// @notice Thrown when the caller is not PoolManager
    error NotPoolManager();

    /// @notice Only allow calls from the PoolManager contract
    modifier onlyPoolManager() {
        if (msg.sender != address(poolManager)) revert NotPoolManager();
        _;
    }

    constructor(IPoolManager _poolManager) {
        poolManager = _poolManager;
    }
}
// SPDX--License-Identifier: MIT
/* pragma solidity ^0.8.0; */

/// @title Library for reverting with custom errors efficiently
/// @notice Contains functions for reverting with custom errors with different argument types efficiently
/// @dev To use this library, declare `using CustomRevert for bytes4;` and replace `revert CustomError()` with
/// `CustomError.selector.revertWith()`
/// @dev The functions may tamper with the free memory pointer but it is fine since the call context is exited immediately
library CustomRevert {
    /// @dev ERC-7751 error for wrapping bubbled up reverts
    error WrappedError(address target, bytes4 selector, bytes reason, bytes details);

    /// @dev Reverts with the selector of a custom error in the scratch space
    function revertWith(bytes4 selector) internal pure {
        assembly ("memory-safe") {
            mstore(0, selector)
            revert(0, 0x04)
        }
    }

    /// @dev Reverts with a custom error with an address argument in the scratch space
    function revertWith(bytes4 selector, address addr) internal pure {
        assembly ("memory-safe") {
            mstore(0, selector)
            mstore(0x04, and(addr, 0xffffffffffffffffffffffffffffffffffffffff))
            revert(0, 0x24)
        }
    }

    /// @dev Reverts with a custom error with an int24 argument in the scratch space
    function revertWith(bytes4 selector, int24 value) internal pure {
        assembly ("memory-safe") {
            mstore(0, selector)
            mstore(0x04, signextend(2, value))
            revert(0, 0x24)
        }
    }

    /// @dev Reverts with a custom error with a uint160 argument in the scratch space
    function revertWith(bytes4 selector, uint160 value) internal pure {
        assembly ("memory-safe") {
            mstore(0, selector)
            mstore(0x04, and(value, 0xffffffffffffffffffffffffffffffffffffffff))
            revert(0, 0x24)
        }
    }

    /// @dev Reverts with a custom error with two int24 arguments
    function revertWith(bytes4 selector, int24 value1, int24 value2) internal pure {
        assembly ("memory-safe") {
            let fmp := mload(0x40)
            mstore(fmp, selector)
            mstore(add(fmp, 0x04), signextend(2, value1))
            mstore(add(fmp, 0x24), signextend(2, value2))
            revert(fmp, 0x44)
        }
    }

    /// @dev Reverts with a custom error with two uint160 arguments
    function revertWith(bytes4 selector, uint160 value1, uint160 value2) internal pure {
        assembly ("memory-safe") {
            let fmp := mload(0x40)
            mstore(fmp, selector)
            mstore(add(fmp, 0x04), and(value1, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(fmp, 0x24), and(value2, 0xffffffffffffffffffffffffffffffffffffffff))
            revert(fmp, 0x44)
        }
    }

    /// @dev Reverts with a custom error with two address arguments
    function revertWith(bytes4 selector, address value1, address value2) internal pure {
        assembly ("memory-safe") {
            let fmp := mload(0x40)
            mstore(fmp, selector)
            mstore(add(fmp, 0x04), and(value1, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(fmp, 0x24), and(value2, 0xffffffffffffffffffffffffffffffffffffffff))
            revert(fmp, 0x44)
        }
    }

    /// @notice bubble up the revert message returned by a call and revert with a wrapped ERC-7751 error
    /// @dev this method can be vulnerable to revert data bombs
    function bubbleUpAndRevertWith(
        address revertingContract,
        bytes4 revertingFunctionSelector,
        bytes4 additionalContext
    ) internal pure {
        bytes4 wrappedErrorSelector = WrappedError.selector;
        assembly ("memory-safe") {
            // Ensure the size of the revert data is a multiple of 32 bytes
            let encodedDataSize := mul(div(add(returndatasize(), 31), 32), 32)

            let fmp := mload(0x40)

            // Encode wrapped error selector, address, function selector, offset, additional context, size, revert reason
            mstore(fmp, wrappedErrorSelector)
            mstore(add(fmp, 0x04), and(revertingContract, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(
                add(fmp, 0x24),
                and(revertingFunctionSelector, 0xffffffff00000000000000000000000000000000000000000000000000000000)
            )
            // offset revert reason
            mstore(add(fmp, 0x44), 0x80)
            // offset additional context
            mstore(add(fmp, 0x64), add(0xa0, encodedDataSize))
            // size revert reason
            mstore(add(fmp, 0x84), returndatasize())
            // revert reason
            returndatacopy(add(fmp, 0xa4), 0, returndatasize())
            // size additional context
            mstore(add(fmp, add(0xa4, encodedDataSize)), 0x04)
            // additional context
            mstore(
                add(fmp, add(0xc4, encodedDataSize)),
                and(additionalContext, 0xffffffff00000000000000000000000000000000000000000000000000000000)
            )
            revert(fmp, add(0xe4, encodedDataSize))
        }
    }
}
// SPDX--License-Identifier: MIT
/* pragma solidity ^0.8.0; */
/* import {CustomRevert} from "./CustomRevert.sol"; */

/// @notice Library of helper functions for a pools LP fee
library LPFeeLibrary {
    using LPFeeLibrary for uint24;
    using CustomRevert for bytes4;

    /// @notice Thrown when the static or dynamic fee on a pool exceeds 100%.
    error LPFeeTooLarge(uint24 fee);

    /// @notice An lp fee of exactly 0b1000000... signals a dynamic fee pool. This isn't a valid static fee as it is > MAX_LP_FEE
    uint24 public constant DYNAMIC_FEE_FLAG = 0x800000;

    /// @notice the second bit of the fee returned by beforeSwap is used to signal if the stored LP fee should be overridden in this swap
    // only dynamic-fee pools can return a fee via the beforeSwap hook
    uint24 public constant OVERRIDE_FEE_FLAG = 0x400000;

    /// @notice mask to remove the override fee flag from a fee returned by the beforeSwaphook
    uint24 public constant REMOVE_OVERRIDE_MASK = 0xBFFFFF;

    /// @notice the lp fee is represented in hundredths of a bip, so the max is 100%
    uint24 public constant MAX_LP_FEE = 1000000;

    /// @notice returns true if a pool's LP fee signals that the pool has a dynamic fee
    /// @param self The fee to check
    /// @return bool True of the fee is dynamic
    function isDynamicFee(uint24 self) internal pure returns (bool) {
        return self == DYNAMIC_FEE_FLAG;
    }

    /// @notice returns true if an LP fee is valid, aka not above the maximum permitted fee
    /// @param self The fee to check
    /// @return bool True of the fee is valid
    function isValid(uint24 self) internal pure returns (bool) {
        return self <= MAX_LP_FEE;
    }

    /// @notice validates whether an LP fee is larger than the maximum, and reverts if invalid
    /// @param self The fee to validate
    function validate(uint24 self) internal pure {
        if (!self.isValid()) LPFeeTooLarge.selector.revertWith(self);
    }

    /// @notice gets and validates the initial LP fee for a pool. Dynamic fee pools have an initial fee of 0.
    /// @dev if a dynamic fee pool wants a non-0 initial fee, it should call `updateDynamicLPFee` in the afterInitialize hook
    /// @param self The fee to get the initial LP from
    /// @return initialFee 0 if the fee is dynamic, otherwise the fee (if valid)
    function getInitialLPFee(uint24 self) internal pure returns (uint24) {
        // the initial fee for a dynamic fee pool is 0
        if (self.isDynamicFee()) return 0;
        self.validate();
        return self;
    }

    /// @notice returns true if the fee has the override flag set (2nd highest bit of the uint24)
    /// @param self The fee to check
    /// @return bool True of the fee has the override flag set
    function isOverride(uint24 self) internal pure returns (bool) {
        return self & OVERRIDE_FEE_FLAG != 0;
    }

    /// @notice returns a fee with the override flag removed
    /// @param self The fee to remove the override flag from
    /// @return fee The fee without the override flag set
    function removeOverrideFlag(uint24 self) internal pure returns (uint24) {
        return self & REMOVE_OVERRIDE_MASK;
    }

    /// @notice Removes the override flag and validates the fee (reverts if the fee is too large)
    /// @param self The fee to remove the override flag from, and then validate
    /// @return fee The fee without the override flag set (if valid)
    function removeOverrideFlagAndValidate(uint24 self) internal pure returns (uint24 fee) {
        fee = self.removeOverrideFlag();
        fee.validate();
    }
}
// SPDX--License-Identifier: MIT
/* pragma solidity ^0.8.0; */
/* import {CustomRevert} from "./CustomRevert.sol"; */

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    using CustomRevert for bytes4;

    error SafeCastOverflow();

    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param x The uint256 to be downcasted
    /// @return y The downcasted integer, now type uint160
    function toUint160(uint256 x) internal pure returns (uint160 y) {
        y = uint160(x);
        if (y != x) SafeCastOverflow.selector.revertWith();
    }

    /// @notice Cast a uint256 to a uint128, revert on overflow
    /// @param x The uint256 to be downcasted
    /// @return y The downcasted integer, now type uint128
    function toUint128(uint256 x) internal pure returns (uint128 y) {
        y = uint128(x);
        if (x != y) SafeCastOverflow.selector.revertWith();
    }

    /// @notice Cast a int128 to a uint128, revert on overflow or underflow
    /// @param x The int128 to be casted
    /// @return y The casted integer, now type uint128
    function toUint128(int128 x) internal pure returns (uint128 y) {
        if (x < 0) SafeCastOverflow.selector.revertWith();
        y = uint128(x);
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param x The int256 to be downcasted
    /// @return y The downcasted integer, now type int128
    function toInt128(int256 x) internal pure returns (int128 y) {
        y = int128(x);
        if (y != x) SafeCastOverflow.selector.revertWith();
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param x The uint256 to be casted
    /// @return y The casted integer, now type int256
    function toInt256(uint256 x) internal pure returns (int256 y) {
        y = int256(x);
        if (y < 0) SafeCastOverflow.selector.revertWith();
    }

    /// @notice Cast a uint256 to a int128, revert on overflow
    /// @param x The uint256 to be downcasted
    /// @return The downcasted integer, now type int128
    function toInt128(uint256 x) internal pure returns (int128) {
        if (x >= 1 << 127) SafeCastOverflow.selector.revertWith();
        return int128(int256(x));
    }
}
// SPDX--License-Identifier: MIT
/* pragma solidity ^0.8.0; */

// Return type of the beforeSwap hook.
// Upper 128 bits is the delta in specified tokens. Lower 128 bits is delta in unspecified tokens (to match the afterSwap hook)
type BeforeSwapDelta is int256;

// Creates a BeforeSwapDelta from specified and unspecified
function toBeforeSwapDelta(int128 deltaSpecified, int128 deltaUnspecified)
    pure
    returns (BeforeSwapDelta beforeSwapDelta)
{
    assembly ("memory-safe") {
        beforeSwapDelta := or(shl(128, deltaSpecified), and(sub(shl(128, 1), 1), deltaUnspecified))
    }
}

/// @notice Library for getting the specified and unspecified deltas from the BeforeSwapDelta type
library BeforeSwapDeltaLibrary {
    /// @notice A BeforeSwapDelta of 0
    BeforeSwapDelta public constant ZERO_DELTA = BeforeSwapDelta.wrap(0);

    /// extracts int128 from the upper 128 bits of the BeforeSwapDelta
    /// returned by beforeSwap
    function getSpecifiedDelta(BeforeSwapDelta delta) internal pure returns (int128 deltaSpecified) {
        assembly ("memory-safe") {
            deltaSpecified := sar(128, delta)
        }
    }

    /// extracts int128 from the lower 128 bits of the BeforeSwapDelta
    /// returned by beforeSwap and afterSwap
    function getUnspecifiedDelta(BeforeSwapDelta delta) internal pure returns (int128 deltaUnspecified) {
        assembly ("memory-safe") {
            deltaUnspecified := signextend(15, delta)
        }
    }
}
// SPDX--License-Identifier: MIT

/* pragma solidity ^0.8.0; */

/// @notice Parses bytes returned from hooks and the byte selector used to check return selectors from hooks.
/// @dev parseSelector also is used to parse the expected selector
/// For parsing hook returns, note that all hooks return either bytes4 or (bytes4, 32-byte-delta) or (bytes4, 32-byte-delta, uint24).
library ParseBytes {
    function parseSelector(bytes memory result) internal pure returns (bytes4 selector) {
        // equivalent: (selector,) = abi.decode(result, (bytes4, int256));
        assembly ("memory-safe") {
            selector := mload(add(result, 0x20))
        }
    }

    function parseFee(bytes memory result) internal pure returns (uint24 lpFee) {
        // equivalent: (,, lpFee) = abi.decode(result, (bytes4, int256, uint24));
        assembly ("memory-safe") {
            lpFee := mload(add(result, 0x60))
        }
    }

    function parseReturnDelta(bytes memory result) internal pure returns (int256 hookReturn) {
        // equivalent: (, hookReturnDelta) = abi.decode(result, (bytes4, int256));
        assembly ("memory-safe") {
            hookReturn := mload(add(result, 0x40))
        }
    }
}
// SPDX--License-Identifier: MIT
/* pragma solidity ^0.8.0; */
/* import {PoolKey} from "../types/PoolKey.sol"; */
/* import {IHooks} from "../interfaces/IHooks.sol"; */
/* import {SafeCast} from "./SafeCast.sol"; */
/* import {LPFeeLibrary} from "./LPFeeLibrary.sol"; */
/* import {BalanceDelta, toBalanceDelta, BalanceDeltaLibrary} from "../types/BalanceDelta.sol"; */
/* import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "../types/BeforeSwapDelta.sol"; */
/* import {IPoolManager} from "../interfaces/IPoolManager.sol"; */
/* import {ParseBytes} from "./ParseBytes.sol"; */
/* import {CustomRevert} from "./CustomRevert.sol"; */

/// @notice V4 decides whether to invoke specific hooks by inspecting the least significant bits
/// of the address that the hooks contract is deployed to.
/// For example, a hooks contract deployed to address: 0x0000000000000000000000000000000000002400
/// has the lowest bits '10 0100 0000 0000' which would cause the 'before initialize' and 'after add liquidity' hooks to be used.
library Hooks {
    using LPFeeLibrary for uint24;
    using Hooks for IHooks;
    using SafeCast for int256;
    using BeforeSwapDeltaLibrary for BeforeSwapDelta;
    using ParseBytes for bytes;
    using CustomRevert for bytes4;

    uint160 internal constant ALL_HOOK_MASK = uint160((1 << 14) - 1);

    uint160 internal constant BEFORE_INITIALIZE_FLAG = 1 << 13;
    uint160 internal constant AFTER_INITIALIZE_FLAG = 1 << 12;

    uint160 internal constant BEFORE_ADD_LIQUIDITY_FLAG = 1 << 11;
    uint160 internal constant AFTER_ADD_LIQUIDITY_FLAG = 1 << 10;

    uint160 internal constant BEFORE_REMOVE_LIQUIDITY_FLAG = 1 << 9;
    uint160 internal constant AFTER_REMOVE_LIQUIDITY_FLAG = 1 << 8;

    uint160 internal constant BEFORE_SWAP_FLAG = 1 << 7;
    uint160 internal constant AFTER_SWAP_FLAG = 1 << 6;

    uint160 internal constant BEFORE_DONATE_FLAG = 1 << 5;
    uint160 internal constant AFTER_DONATE_FLAG = 1 << 4;

    uint160 internal constant BEFORE_SWAP_RETURNS_DELTA_FLAG = 1 << 3;
    uint160 internal constant AFTER_SWAP_RETURNS_DELTA_FLAG = 1 << 2;
    uint160 internal constant AFTER_ADD_LIQUIDITY_RETURNS_DELTA_FLAG = 1 << 1;
    uint160 internal constant AFTER_REMOVE_LIQUIDITY_RETURNS_DELTA_FLAG = 1 << 0;

    struct Permissions {
        bool beforeInitialize;
        bool afterInitialize;
        bool beforeAddLiquidity;
        bool afterAddLiquidity;
        bool beforeRemoveLiquidity;
        bool afterRemoveLiquidity;
        bool beforeSwap;
        bool afterSwap;
        bool beforeDonate;
        bool afterDonate;
        bool beforeSwapReturnDelta;
        bool afterSwapReturnDelta;
        bool afterAddLiquidityReturnDelta;
        bool afterRemoveLiquidityReturnDelta;
    }

    /// @notice Thrown if the address will not lead to the specified hook calls being called
    /// @param hooks The address of the hooks contract
    error HookAddressNotValid(address hooks);

    /// @notice Hook did not return its selector
    error InvalidHookResponse();

    /// @notice Additional context for ERC-7751 wrapped error when a hook call fails
    error HookCallFailed();

    /// @notice The hook's delta changed the swap from exactIn to exactOut or vice versa
    error HookDeltaExceedsSwapAmount();

    /// @notice Utility function intended to be used in hook constructors to ensure
    /// the deployed hooks address causes the intended hooks to be called
    /// @param permissions The hooks that are intended to be called
    /// @dev permissions param is memory as the function will be called from constructors
    function validateHookPermissions(IHooks self, Permissions memory permissions) internal pure {
        if (
            permissions.beforeInitialize != self.hasPermission(BEFORE_INITIALIZE_FLAG)
                || permissions.afterInitialize != self.hasPermission(AFTER_INITIALIZE_FLAG)
                || permissions.beforeAddLiquidity != self.hasPermission(BEFORE_ADD_LIQUIDITY_FLAG)
                || permissions.afterAddLiquidity != self.hasPermission(AFTER_ADD_LIQUIDITY_FLAG)
                || permissions.beforeRemoveLiquidity != self.hasPermission(BEFORE_REMOVE_LIQUIDITY_FLAG)
                || permissions.afterRemoveLiquidity != self.hasPermission(AFTER_REMOVE_LIQUIDITY_FLAG)
                || permissions.beforeSwap != self.hasPermission(BEFORE_SWAP_FLAG)
                || permissions.afterSwap != self.hasPermission(AFTER_SWAP_FLAG)
                || permissions.beforeDonate != self.hasPermission(BEFORE_DONATE_FLAG)
                || permissions.afterDonate != self.hasPermission(AFTER_DONATE_FLAG)
                || permissions.beforeSwapReturnDelta != self.hasPermission(BEFORE_SWAP_RETURNS_DELTA_FLAG)
                || permissions.afterSwapReturnDelta != self.hasPermission(AFTER_SWAP_RETURNS_DELTA_FLAG)
                || permissions.afterAddLiquidityReturnDelta != self.hasPermission(AFTER_ADD_LIQUIDITY_RETURNS_DELTA_FLAG)
                || permissions.afterRemoveLiquidityReturnDelta
                    != self.hasPermission(AFTER_REMOVE_LIQUIDITY_RETURNS_DELTA_FLAG)
        ) {
            HookAddressNotValid.selector.revertWith(address(self));
        }
    }

    /// @notice Ensures that the hook address includes at least one hook flag or dynamic fees, or is the 0 address
    /// @param self The hook to verify
    /// @param fee The fee of the pool the hook is used with
    /// @return bool True if the hook address is valid
    function isValidHookAddress(IHooks self, uint24 fee) internal pure returns (bool) {
        // The hook can only have a flag to return a hook delta on an action if it also has the corresponding action flag
        if (!self.hasPermission(BEFORE_SWAP_FLAG) && self.hasPermission(BEFORE_SWAP_RETURNS_DELTA_FLAG)) return false;
        if (!self.hasPermission(AFTER_SWAP_FLAG) && self.hasPermission(AFTER_SWAP_RETURNS_DELTA_FLAG)) return false;
        if (!self.hasPermission(AFTER_ADD_LIQUIDITY_FLAG) && self.hasPermission(AFTER_ADD_LIQUIDITY_RETURNS_DELTA_FLAG))
        {
            return false;
        }
        if (
            !self.hasPermission(AFTER_REMOVE_LIQUIDITY_FLAG)
                && self.hasPermission(AFTER_REMOVE_LIQUIDITY_RETURNS_DELTA_FLAG)
        ) return false;

        // If there is no hook contract set, then fee cannot be dynamic
        // If a hook contract is set, it must have at least 1 flag set, or have a dynamic fee
        return address(self) == address(0)
            ? !fee.isDynamicFee()
            : (uint160(address(self)) & ALL_HOOK_MASK > 0 || fee.isDynamicFee());
    }

    /// @notice performs a hook call using the given calldata on the given hook that doesn't return a delta
    /// @return result The complete data returned by the hook
    function callHook(IHooks self, bytes memory data) internal returns (bytes memory result) {
        bool success;
        assembly ("memory-safe") {
            success := call(gas(), self, 0, add(data, 0x20), mload(data), 0, 0)
        }
        // Revert with FailedHookCall, containing any error message to bubble up
        if (!success) CustomRevert.bubbleUpAndRevertWith(address(self), bytes4(data), HookCallFailed.selector);

        // The call was successful, fetch the returned data
        assembly ("memory-safe") {
            // allocate result byte array from the free memory pointer
            result := mload(0x40)
            // store new free memory pointer at the end of the array padded to 32 bytes
            mstore(0x40, add(result, and(add(returndatasize(), 0x3f), not(0x1f))))
            // store length in memory
            mstore(result, returndatasize())
            // copy return data to result
            returndatacopy(add(result, 0x20), 0, returndatasize())
        }

        // Length must be at least 32 to contain the selector. Check expected selector and returned selector match.
        if (result.length < 32 || result.parseSelector() != data.parseSelector()) {
            InvalidHookResponse.selector.revertWith();
        }
    }

    /// @notice performs a hook call using the given calldata on the given hook
    /// @return int256 The delta returned by the hook
    function callHookWithReturnDelta(IHooks self, bytes memory data, bool parseReturn) internal returns (int256) {
        bytes memory result = callHook(self, data);

        // If this hook wasn't meant to return something, default to 0 delta
        if (!parseReturn) return 0;

        // A length of 64 bytes is required to return a bytes4, and a 32 byte delta
        if (result.length != 64) InvalidHookResponse.selector.revertWith();
        return result.parseReturnDelta();
    }

    /// @notice modifier to prevent calling a hook if they initiated the action
    modifier noSelfCall(IHooks self) {
        if (msg.sender != address(self)) {
            _;
        }
    }

    /// @notice calls beforeInitialize hook if permissioned and validates return value
    function beforeInitialize(IHooks self, PoolKey memory key, uint160 sqrtPriceX96) internal noSelfCall(self) {
        if (self.hasPermission(BEFORE_INITIALIZE_FLAG)) {
            self.callHook(abi.encodeCall(IHooks.beforeInitialize, (msg.sender, key, sqrtPriceX96)));
        }
    }

    /// @notice calls afterInitialize hook if permissioned and validates return value
    function afterInitialize(IHooks self, PoolKey memory key, uint160 sqrtPriceX96, int24 tick)
        internal
        noSelfCall(self)
    {
        if (self.hasPermission(AFTER_INITIALIZE_FLAG)) {
            self.callHook(abi.encodeCall(IHooks.afterInitialize, (msg.sender, key, sqrtPriceX96, tick)));
        }
    }

    /// @notice calls beforeModifyLiquidity hook if permissioned and validates return value
    function beforeModifyLiquidity(
        IHooks self,
        PoolKey memory key,
        IPoolManager.ModifyLiquidityParams memory params,
        bytes calldata hookData
    ) internal noSelfCall(self) {
        if (params.liquidityDelta > 0 && self.hasPermission(BEFORE_ADD_LIQUIDITY_FLAG)) {
            self.callHook(abi.encodeCall(IHooks.beforeAddLiquidity, (msg.sender, key, params, hookData)));
        } else if (params.liquidityDelta <= 0 && self.hasPermission(BEFORE_REMOVE_LIQUIDITY_FLAG)) {
            self.callHook(abi.encodeCall(IHooks.beforeRemoveLiquidity, (msg.sender, key, params, hookData)));
        }
    }

    /// @notice calls afterModifyLiquidity hook if permissioned and validates return value
    function afterModifyLiquidity(
        IHooks self,
        PoolKey memory key,
        IPoolManager.ModifyLiquidityParams memory params,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes calldata hookData
    ) internal returns (BalanceDelta callerDelta, BalanceDelta hookDelta) {
        if (msg.sender == address(self)) return (delta, BalanceDeltaLibrary.ZERO_DELTA);

        callerDelta = delta;
        if (params.liquidityDelta > 0) {
            if (self.hasPermission(AFTER_ADD_LIQUIDITY_FLAG)) {
                hookDelta = BalanceDelta.wrap(
                    self.callHookWithReturnDelta(
                        abi.encodeCall(
                            IHooks.afterAddLiquidity, (msg.sender, key, params, delta, feesAccrued, hookData)
                        ),
                        self.hasPermission(AFTER_ADD_LIQUIDITY_RETURNS_DELTA_FLAG)
                    )
                );
                callerDelta = callerDelta - hookDelta;
            }
        } else {
            if (self.hasPermission(AFTER_REMOVE_LIQUIDITY_FLAG)) {
                hookDelta = BalanceDelta.wrap(
                    self.callHookWithReturnDelta(
                        abi.encodeCall(
                            IHooks.afterRemoveLiquidity, (msg.sender, key, params, delta, feesAccrued, hookData)
                        ),
                        self.hasPermission(AFTER_REMOVE_LIQUIDITY_RETURNS_DELTA_FLAG)
                    )
                );
                callerDelta = callerDelta - hookDelta;
            }
        }
    }

    /// @notice calls beforeSwap hook if permissioned and validates return value
    function beforeSwap(IHooks self, PoolKey memory key, IPoolManager.SwapParams memory params, bytes calldata hookData)
        internal
        returns (int256 amountToSwap, BeforeSwapDelta hookReturn, uint24 lpFeeOverride)
    {
        amountToSwap = params.amountSpecified;
        if (msg.sender == address(self)) return (amountToSwap, BeforeSwapDeltaLibrary.ZERO_DELTA, lpFeeOverride);

        if (self.hasPermission(BEFORE_SWAP_FLAG)) {
            bytes memory result = callHook(self, abi.encodeCall(IHooks.beforeSwap, (msg.sender, key, params, hookData)));

            // A length of 96 bytes is required to return a bytes4, a 32 byte delta, and an LP fee
            if (result.length != 96) InvalidHookResponse.selector.revertWith();

            // dynamic fee pools that want to override the cache fee, return a valid fee with the override flag. If override flag
            // is set but an invalid fee is returned, the transaction will revert. Otherwise the current LP fee will be used
            if (key.fee.isDynamicFee()) lpFeeOverride = result.parseFee();

            // skip this logic for the case where the hook return is 0
            if (self.hasPermission(BEFORE_SWAP_RETURNS_DELTA_FLAG)) {
                hookReturn = BeforeSwapDelta.wrap(result.parseReturnDelta());

                // any return in unspecified is passed to the afterSwap hook for handling
                int128 hookDeltaSpecified = hookReturn.getSpecifiedDelta();

                // Update the swap amount according to the hook's return, and check that the swap type doesn't change (exact input/output)
                if (hookDeltaSpecified != 0) {
                    bool exactInput = amountToSwap < 0;
                    amountToSwap += hookDeltaSpecified;
                    if (exactInput ? amountToSwap > 0 : amountToSwap < 0) {
                        HookDeltaExceedsSwapAmount.selector.revertWith();
                    }
                }
            }
        }
    }

    /// @notice calls afterSwap hook if permissioned and validates return value
    function afterSwap(
        IHooks self,
        PoolKey memory key,
        IPoolManager.SwapParams memory params,
        BalanceDelta swapDelta,
        bytes calldata hookData,
        BeforeSwapDelta beforeSwapHookReturn
    ) internal returns (BalanceDelta, BalanceDelta) {
        if (msg.sender == address(self)) return (swapDelta, BalanceDeltaLibrary.ZERO_DELTA);

        int128 hookDeltaSpecified = beforeSwapHookReturn.getSpecifiedDelta();
        int128 hookDeltaUnspecified = beforeSwapHookReturn.getUnspecifiedDelta();

        if (self.hasPermission(AFTER_SWAP_FLAG)) {
            hookDeltaUnspecified += self.callHookWithReturnDelta(
                abi.encodeCall(IHooks.afterSwap, (msg.sender, key, params, swapDelta, hookData)),
                self.hasPermission(AFTER_SWAP_RETURNS_DELTA_FLAG)
            ).toInt128();
        }

        BalanceDelta hookDelta;
        if (hookDeltaUnspecified != 0 || hookDeltaSpecified != 0) {
            hookDelta = (params.amountSpecified < 0 == params.zeroForOne)
                ? toBalanceDelta(hookDeltaSpecified, hookDeltaUnspecified)
                : toBalanceDelta(hookDeltaUnspecified, hookDeltaSpecified);

            // the caller has to pay for (or receive) the hook's delta
            swapDelta = swapDelta - hookDelta;
        }
        return (swapDelta, hookDelta);
    }

    /// @notice calls beforeDonate hook if permissioned and validates return value
    function beforeDonate(IHooks self, PoolKey memory key, uint256 amount0, uint256 amount1, bytes calldata hookData)
        internal
        noSelfCall(self)
    {
        if (self.hasPermission(BEFORE_DONATE_FLAG)) {
            self.callHook(abi.encodeCall(IHooks.beforeDonate, (msg.sender, key, amount0, amount1, hookData)));
        }
    }

    /// @notice calls afterDonate hook if permissioned and validates return value
    function afterDonate(IHooks self, PoolKey memory key, uint256 amount0, uint256 amount1, bytes calldata hookData)
        internal
        noSelfCall(self)
    {
        if (self.hasPermission(AFTER_DONATE_FLAG)) {
            self.callHook(abi.encodeCall(IHooks.afterDonate, (msg.sender, key, amount0, amount1, hookData)));
        }
    }

    function hasPermission(IHooks self, uint160 flag) internal pure returns (bool) {
        return uint160(address(self)) & flag != 0;
    }
}
// SPDX--License-Identifier: MIT
/* pragma solidity ^0.8.0; */
/* import {SafeCast} from "../libraries/SafeCast.sol"; */

/// @dev Two `int128` values packed into a single `int256` where the upper 128 bits represent the amount0
/// and the lower 128 bits represent the amount1.
type BalanceDelta is int256;

using {add as +, sub as -, eq as ==, neq as !=} for BalanceDelta global;
using BalanceDeltaLibrary for BalanceDelta global;
using SafeCast for int256;

function toBalanceDelta(int128 _amount0, int128 _amount1) pure returns (BalanceDelta balanceDelta) {
    assembly ("memory-safe") {
        balanceDelta := or(shl(128, _amount0), and(sub(shl(128, 1), 1), _amount1))
    }
}

function add(BalanceDelta a, BalanceDelta b) pure returns (BalanceDelta) {
    int256 res0;
    int256 res1;
    assembly ("memory-safe") {
        let a0 := sar(128, a)
        let a1 := signextend(15, a)
        let b0 := sar(128, b)
        let b1 := signextend(15, b)
        res0 := add(a0, b0)
        res1 := add(a1, b1)
    }
    return toBalanceDelta(res0.toInt128(), res1.toInt128());
}

function sub(BalanceDelta a, BalanceDelta b) pure returns (BalanceDelta) {
    int256 res0;
    int256 res1;
    assembly ("memory-safe") {
        let a0 := sar(128, a)
        let a1 := signextend(15, a)
        let b0 := sar(128, b)
        let b1 := signextend(15, b)
        res0 := sub(a0, b0)
        res1 := sub(a1, b1)
    }
    return toBalanceDelta(res0.toInt128(), res1.toInt128());
}

function eq(BalanceDelta a, BalanceDelta b) pure returns (bool) {
    return BalanceDelta.unwrap(a) == BalanceDelta.unwrap(b);
}

function neq(BalanceDelta a, BalanceDelta b) pure returns (bool) {
    return BalanceDelta.unwrap(a) != BalanceDelta.unwrap(b);
}

/// @notice Library for getting the amount0 and amount1 deltas from the BalanceDelta type
library BalanceDeltaLibrary {
    /// @notice A BalanceDelta of 0
    BalanceDelta public constant ZERO_DELTA = BalanceDelta.wrap(0);

    function amount0(BalanceDelta balanceDelta) internal pure returns (int128 _amount0) {
        assembly ("memory-safe") {
            _amount0 := sar(128, balanceDelta)
        }
    }

    function amount1(BalanceDelta balanceDelta) internal pure returns (int128 _amount1) {
        assembly ("memory-safe") {
            _amount1 := signextend(15, balanceDelta)
        }
    }
}
// SPDX--License-Identifier: MIT
/* pragma solidity ^0.8.0; */
/* import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol"; */
/* import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol"; */
/* import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol"; */
/* import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol"; */
/* import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol"; */
/* import {BeforeSwapDelta} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol"; */
/* import {ImmutableState} from "../base/ImmutableState.sol"; */

/// @title Base Hook
/// @notice abstract contract for hook implementations
abstract contract BaseHook is IHooks, ImmutableState {
    error HookNotImplemented();

    constructor(IPoolManager _manager) ImmutableState(_manager) {
        validateHookAddress(this);
    }

    /// @notice Returns a struct of permissions to signal which hook functions are to be implemented
    /// @dev Used at deployment to validate the address correctly represents the expected permissions
    function getHookPermissions() public pure virtual returns (Hooks.Permissions memory);

    /// @notice Validates the deployed hook address agrees with the expected permissions of the hook
    /// @dev this function is virtual so that we can override it during testing,
    /// which allows us to deploy an implementation to any address
    /// and then etch the bytecode into the correct address
    function validateHookAddress(BaseHook _this) internal pure virtual {
        Hooks.validateHookPermissions(_this, getHookPermissions());
    }

    /// @inheritdoc IHooks
    function beforeInitialize(address sender, PoolKey calldata key, uint160 sqrtPriceX96)
        external
        onlyPoolManager
        returns (bytes4)
    {
        return _beforeInitialize(sender, key, sqrtPriceX96);
    }

    function _beforeInitialize(address, PoolKey calldata, uint160) internal virtual returns (bytes4) {
        revert HookNotImplemented();
    }

    /// @inheritdoc IHooks
    function afterInitialize(address sender, PoolKey calldata key, uint160 sqrtPriceX96, int24 tick)
        external
        onlyPoolManager
        returns (bytes4)
    {
        return _afterInitialize(sender, key, sqrtPriceX96, tick);
    }

    function _afterInitialize(address, PoolKey calldata, uint160, int24) internal virtual returns (bytes4) {
        revert HookNotImplemented();
    }

    /// @inheritdoc IHooks
    function beforeAddLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external onlyPoolManager returns (bytes4) {
        return _beforeAddLiquidity(sender, key, params, hookData);
    }

    function _beforeAddLiquidity(address, PoolKey calldata, IPoolManager.ModifyLiquidityParams calldata, bytes calldata)
        internal
        virtual
        returns (bytes4)
    {
        revert HookNotImplemented();
    }

    /// @inheritdoc IHooks
    function beforeRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external onlyPoolManager returns (bytes4) {
        return _beforeRemoveLiquidity(sender, key, params, hookData);
    }

    function _beforeRemoveLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) internal virtual returns (bytes4) {
        revert HookNotImplemented();
    }

    /// @inheritdoc IHooks
    function afterAddLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes calldata hookData
    ) external onlyPoolManager returns (bytes4, BalanceDelta) {
        return _afterAddLiquidity(sender, key, params, delta, feesAccrued, hookData);
    }

    function _afterAddLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        BalanceDelta,
        BalanceDelta,
        bytes calldata
    ) internal virtual returns (bytes4, BalanceDelta) {
        revert HookNotImplemented();
    }

    /// @inheritdoc IHooks
    function afterRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes calldata hookData
    ) external onlyPoolManager returns (bytes4, BalanceDelta) {
        return _afterRemoveLiquidity(sender, key, params, delta, feesAccrued, hookData);
    }

    function _afterRemoveLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        BalanceDelta,
        BalanceDelta,
        bytes calldata
    ) internal virtual returns (bytes4, BalanceDelta) {
        revert HookNotImplemented();
    }

    /// @inheritdoc IHooks
    function beforeSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata hookData
    ) external onlyPoolManager returns (bytes4, BeforeSwapDelta, uint24) {
        return _beforeSwap(sender, key, params, hookData);
    }

    function _beforeSwap(address, PoolKey calldata, IPoolManager.SwapParams calldata, bytes calldata)
        internal
        virtual
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        revert HookNotImplemented();
    }

    /// @inheritdoc IHooks
    function afterSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external onlyPoolManager returns (bytes4, int128) {
        return _afterSwap(sender, key, params, delta, hookData);
    }

    function _afterSwap(address, PoolKey calldata, IPoolManager.SwapParams calldata, BalanceDelta, bytes calldata)
        internal
        virtual
        returns (bytes4, int128)
    {
        revert HookNotImplemented();
    }

    /// @inheritdoc IHooks
    function beforeDonate(
        address sender,
        PoolKey calldata key,
        uint256 amount0,
        uint256 amount1,
        bytes calldata hookData
    ) external onlyPoolManager returns (bytes4) {
        return _beforeDonate(sender, key, amount0, amount1, hookData);
    }

    function _beforeDonate(address, PoolKey calldata, uint256, uint256, bytes calldata)
        internal
        virtual
        returns (bytes4)
    {
        revert HookNotImplemented();
    }

    /// @inheritdoc IHooks
    function afterDonate(
        address sender,
        PoolKey calldata key,
        uint256 amount0,
        uint256 amount1,
        bytes calldata hookData
    ) external onlyPoolManager returns (bytes4) {
        return _afterDonate(sender, key, amount0, amount1, hookData);
    }

    function _afterDonate(address, PoolKey calldata, uint256, uint256, bytes calldata)
        internal
        virtual
        returns (bytes4)
    {
        revert HookNotImplemented();
    }
}
// SPDX--License-Identifier: GPL-2.0-or-later

/* pragma solidity >=0.8.0; */
/* import {IVault as IEVCVault} from "ethereum-vault-connector/interfaces/IVault.sol"; */

// Full interface of EVault and all it's modules

/// @title IInitialize
/// @notice Interface of the initialization module of EVault
interface IInitialize {
    /// @notice Initialization of the newly deployed proxy contract
    /// @param proxyCreator Account which created the proxy or should be the initial governor
    function initialize(address proxyCreator) external;
}

/// @title IERC20
/// @notice Interface of the EVault's Initialize module
interface IEVaultERC20 {
    /// @notice Vault share token (eToken) name, ie "Euler Vault: DAI"
    /// @return The name of the eToken
    function name() external view returns (string memory);

    /// @notice Vault share token (eToken) symbol, ie "eDAI"
    /// @return The symbol of the eToken
    function symbol() external view returns (string memory);

    /// @notice Decimals, the same as the asset's or 18 if the asset doesn't implement `decimals()`
    /// @return The decimals of the eToken
    function decimals() external view returns (uint8);

    /// @notice Sum of all eToken balances
    /// @return The total supply of the eToken
    function totalSupply() external view returns (uint256);

    /// @notice Balance of a particular account, in eTokens
    /// @param account Address to query
    /// @return The balance of the account
    function balanceOf(address account) external view returns (uint256);

    /// @notice Retrieve the current allowance
    /// @param holder The account holding the eTokens
    /// @param spender Trusted address
    /// @return The allowance from holder for spender
    function allowance(address holder, address spender) external view returns (uint256);

    /// @notice Transfer eTokens to another address
    /// @param to Recipient account
    /// @param amount In shares.
    /// @return True if transfer succeeded
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Transfer eTokens from one address to another
    /// @param from This address must've approved the to address
    /// @param to Recipient account
    /// @param amount In shares
    /// @return True if transfer succeeded
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /// @notice Allow spender to access an amount of your eTokens
    /// @param spender Trusted address
    /// @param amount Use max uint for "infinite" allowance
    /// @return True if approval succeeded
    function approve(address spender, uint256 amount) external returns (bool);
}

/// @title IToken
/// @notice Interface of the EVault's Token module
interface IToken is IEVaultERC20 {
    /// @notice Transfer the full eToken balance of an address to another
    /// @param from This address must've approved the to address
    /// @param to Recipient account
    /// @return True if transfer succeeded
    function transferFromMax(address from, address to) external returns (bool);
}

/// @title IERC4626
/// @notice Interface of an ERC4626 vault
interface IERC4626 {
    /// @notice Vault's underlying asset
    /// @return The vault's underlying asset
    function asset() external view returns (address);

    /// @notice Total amount of managed assets, cash and borrows
    /// @return The total amount of assets
    function totalAssets() external view returns (uint256);

    /// @notice Calculate amount of assets corresponding to the requested shares amount
    /// @param shares Amount of shares to convert
    /// @return The amount of assets
    function convertToAssets(uint256 shares) external view returns (uint256);

    /// @notice Calculate amount of shares corresponding to the requested assets amount
    /// @param assets Amount of assets to convert
    /// @return The amount of shares
    function convertToShares(uint256 assets) external view returns (uint256);

    /// @notice Fetch the maximum amount of assets a user can deposit
    /// @param account Address to query
    /// @return The max amount of assets the account can deposit
    function maxDeposit(address account) external view returns (uint256);

    /// @notice Calculate an amount of shares that would be created by depositing assets
    /// @param assets Amount of assets deposited
    /// @return Amount of shares received
    function previewDeposit(uint256 assets) external view returns (uint256);

    /// @notice Fetch the maximum amount of shares a user can mint
    /// @param account Address to query
    /// @return The max amount of shares the account can mint
    function maxMint(address account) external view returns (uint256);

    /// @notice Calculate an amount of assets that would be required to mint requested amount of shares
    /// @param shares Amount of shares to be minted
    /// @return Required amount of assets
    function previewMint(uint256 shares) external view returns (uint256);

    /// @notice Fetch the maximum amount of assets a user is allowed to withdraw
    /// @param owner Account holding the shares
    /// @return The maximum amount of assets the owner is allowed to withdraw
    function maxWithdraw(address owner) external view returns (uint256);

    /// @notice Calculate the amount of shares that will be burned when withdrawing requested amount of assets
    /// @param assets Amount of assets withdrawn
    /// @return Amount of shares burned
    function previewWithdraw(uint256 assets) external view returns (uint256);

    /// @notice Fetch the maximum amount of shares a user is allowed to redeem for assets
    /// @param owner Account holding the shares
    /// @return The maximum amount of shares the owner is allowed to redeem
    function maxRedeem(address owner) external view returns (uint256);

    /// @notice Calculate the amount of assets that will be transferred when redeeming requested amount of shares
    /// @param shares Amount of shares redeemed
    /// @return Amount of assets transferred
    function previewRedeem(uint256 shares) external view returns (uint256);

    /// @notice Transfer requested amount of underlying tokens from sender to the vault pool in return for shares
    /// @param amount Amount of assets to deposit (use max uint256 for full underlying token balance)
    /// @param receiver An account to receive the shares
    /// @return Amount of shares minted
    /// @dev Deposit will round down the amount of assets that are converted to shares. To prevent losses consider using
    /// mint instead.
    function deposit(uint256 amount, address receiver) external returns (uint256);

    /// @notice Transfer underlying tokens from sender to the vault pool in return for requested amount of shares
    /// @param amount Amount of shares to be minted
    /// @param receiver An account to receive the shares
    /// @return Amount of assets deposited
    function mint(uint256 amount, address receiver) external returns (uint256);

    /// @notice Transfer requested amount of underlying tokens from the vault and decrease account's shares balance
    /// @param amount Amount of assets to withdraw
    /// @param receiver Account to receive the withdrawn assets
    /// @param owner Account holding the shares to burn
    /// @return Amount of shares burned
    function withdraw(uint256 amount, address receiver, address owner) external returns (uint256);

    /// @notice Burn requested shares and transfer corresponding underlying tokens from the vault to the receiver
    /// @param amount Amount of shares to burn (use max uint256 to burn full owner balance)
    /// @param receiver Account to receive the withdrawn assets
    /// @param owner Account holding the shares to burn.
    /// @return Amount of assets transferred
    function redeem(uint256 amount, address receiver, address owner) external returns (uint256);
}

/// @title IVault
/// @notice Interface of the EVault's Vault module
interface IVault is IERC4626 {
    /// @notice Balance of the fees accumulator, in shares
    /// @return The accumulated fees in shares
    function accumulatedFees() external view returns (uint256);

    /// @notice Balance of the fees accumulator, in underlying units
    /// @return The accumulated fees in asset units
    function accumulatedFeesAssets() external view returns (uint256);

    /// @notice Address of the original vault creator
    /// @return The address of the creator
    function creator() external view returns (address);

    /// @notice Creates shares for the receiver, from excess asset balances of the vault (not accounted for in `cash`)
    /// @param amount Amount of assets to claim (use max uint256 to claim all available assets)
    /// @param receiver An account to receive the shares
    /// @return Amount of shares minted
    /// @dev Could be used as an alternative deposit flow in certain scenarios. E.g. swap directly to the vault, call
    /// `skim` to claim deposit.
    function skim(uint256 amount, address receiver) external returns (uint256);
}

/// @title IBorrowing
/// @notice Interface of the EVault's Borrowing module
interface IBorrowing {
    /// @notice Sum of all outstanding debts, in underlying units (increases as interest is accrued)
    /// @return The total borrows in asset units
    function totalBorrows() external view returns (uint256);

    /// @notice Sum of all outstanding debts, in underlying units scaled up by shifting
    /// INTERNAL_DEBT_PRECISION_SHIFT bits
    /// @return The total borrows in internal debt precision
    function totalBorrowsExact() external view returns (uint256);

    /// @notice Balance of vault assets as tracked by deposits/withdrawals and borrows/repays
    /// @return The amount of assets the vault tracks as current direct holdings
    function cash() external view returns (uint256);

    /// @notice Debt owed by a particular account, in underlying units
    /// @param account Address to query
    /// @return The debt of the account in asset units
    function debtOf(address account) external view returns (uint256);

    /// @notice Debt owed by a particular account, in underlying units scaled up by shifting
    /// INTERNAL_DEBT_PRECISION_SHIFT bits
    /// @param account Address to query
    /// @return The debt of the account in internal precision
    function debtOfExact(address account) external view returns (uint256);

    /// @notice Retrieves the current interest rate for an asset
    /// @return The interest rate in yield-per-second, scaled by 10**27
    function interestRate() external view returns (uint256);

    /// @notice Retrieves the current interest rate accumulator for an asset
    /// @return An opaque accumulator that increases as interest is accrued
    function interestAccumulator() external view returns (uint256);

    /// @notice Returns an address of the sidecar DToken
    /// @return The address of the DToken
    function dToken() external view returns (address);

    /// @notice Transfer underlying tokens from the vault to the sender, and increase sender's debt
    /// @param amount Amount of assets to borrow (use max uint256 for all available tokens)
    /// @param receiver Account receiving the borrowed tokens
    /// @return Amount of assets borrowed
    function borrow(uint256 amount, address receiver) external returns (uint256);

    /// @notice Transfer underlying tokens from the sender to the vault, and decrease receiver's debt
    /// @param amount Amount of debt to repay in assets (use max uint256 for full debt)
    /// @param receiver Account holding the debt to be repaid
    /// @return Amount of assets repaid
    function repay(uint256 amount, address receiver) external returns (uint256);

    /// @notice Pay off liability with shares ("self-repay")
    /// @param amount In asset units (use max uint256 to repay the debt in full or up to the available deposit)
    /// @param receiver Account to remove debt from by burning sender's shares
    /// @return shares Amount of shares burned
    /// @return debt Amount of debt removed in assets
    /// @dev Equivalent to withdrawing and repaying, but no assets are needed to be present in the vault
    /// @dev Contrary to a regular `repay`, if account is unhealthy, the repay amount must bring the account back to
    /// health, or the operation will revert during account status check
    function repayWithShares(uint256 amount, address receiver) external returns (uint256 shares, uint256 debt);

    /// @notice Take over debt from another account
    /// @param amount Amount of debt in asset units (use max uint256 for all the account's debt)
    /// @param from Account to pull the debt from
    /// @dev Due to internal debt precision accounting, the liability reported on either or both accounts after
    /// calling `pullDebt` may not match the `amount` requested precisely
    function pullDebt(uint256 amount, address from) external;

    /// @notice Request a flash-loan. A onFlashLoan() callback in msg.sender will be invoked, which must repay the loan
    /// to the main Euler address prior to returning.
    /// @param amount In asset units
    /// @param data Passed through to the onFlashLoan() callback, so contracts don't need to store transient data in
    /// storage
    function flashLoan(uint256 amount, bytes calldata data) external;

    /// @notice Updates interest accumulator and totalBorrows, credits reserves, re-targets interest rate, and logs
    /// vault status
    function touch() external;
}

/// @title ILiquidation
/// @notice Interface of the EVault's Liquidation module
interface ILiquidation {
    /// @notice Checks to see if a liquidation would be profitable, without actually doing anything
    /// @param liquidator Address that will initiate the liquidation
    /// @param violator Address that may be in collateral violation
    /// @param collateral Collateral which is to be seized
    /// @return maxRepay Max amount of debt that can be repaid, in asset units
    /// @return maxYield Yield in collateral corresponding to max allowed amount of debt to be repaid, in collateral
    /// balance (shares for vaults)
    function checkLiquidation(address liquidator, address violator, address collateral)
        external
        view
        returns (uint256 maxRepay, uint256 maxYield);

    /// @notice Attempts to perform a liquidation
    /// @param violator Address that may be in collateral violation
    /// @param collateral Collateral which is to be seized
    /// @param repayAssets The amount of underlying debt to be transferred from violator to sender, in asset units (use
    /// max uint256 to repay the maximum possible amount). Meant as slippage check together with `minYieldBalance`
    /// @param minYieldBalance The minimum acceptable amount of collateral to be transferred from violator to sender, in
    /// collateral balance units (shares for vaults).  Meant as slippage check together with `repayAssets`
    /// @dev If `repayAssets` is set to max uint256 it is assumed the caller will perform their own slippage checks to
    /// make sure they are not taking on too much debt. This option is mainly meant for smart contract liquidators
    function liquidate(address violator, address collateral, uint256 repayAssets, uint256 minYieldBalance) external;
}

/// @title IRiskManager
/// @notice Interface of the EVault's RiskManager module
interface IRiskManager {
    /// @notice Retrieve account's total liquidity
    /// @param account Account holding debt in this vault
    /// @param liquidation Flag to indicate if the calculation should be performed in liquidation vs account status
    /// check mode, where different LTV values might apply.
    /// @return collateralValue Total risk adjusted value of all collaterals in unit of account
    /// @return liabilityValue Value of debt in unit of account
    function accountLiquidity(address account, bool liquidation)
        external
        view
        returns (uint256 collateralValue, uint256 liabilityValue);

    /// @notice Retrieve account's liquidity per collateral
    /// @param account Account holding debt in this vault
    /// @param liquidation Flag to indicate if the calculation should be performed in liquidation vs account status
    /// check mode, where different LTV values might apply.
    /// @return collaterals Array of collaterals enabled
    /// @return collateralValues Array of risk adjusted collateral values corresponding to items in collaterals array.
    /// In unit of account
    /// @return liabilityValue Value of debt in unit of account
    function accountLiquidityFull(address account, bool liquidation)
        external
        view
        returns (address[] memory collaterals, uint256[] memory collateralValues, uint256 liabilityValue);

    /// @notice Release control of the account on EVC if no outstanding debt is present
    function disableController() external;

    /// @notice Checks the status of an account and reverts if account is not healthy
    /// @param account The address of the account to be checked
    /// @return magicValue Must return the bytes4 magic value 0xb168c58f (which is a selector of this function) when
    /// account status is valid, or revert otherwise.
    /// @dev Only callable by EVC during status checks
    function checkAccountStatus(address account, address[] calldata collaterals) external view returns (bytes4);

    /// @notice Checks the status of the vault and reverts if caps are exceeded
    /// @return magicValue Must return the bytes4 magic value 0x4b3d1223 (which is a selector of this function) when
    /// account status is valid, or revert otherwise.
    /// @dev Only callable by EVC during status checks
    function checkVaultStatus() external returns (bytes4);
}

/// @title IBalanceForwarder
/// @notice Interface of the EVault's BalanceForwarder module
interface IBalanceForwarder {
    /// @notice Retrieve the address of rewards contract, tracking changes in account's balances
    /// @return The balance tracker address
    function balanceTrackerAddress() external view returns (address);

    /// @notice Retrieves boolean indicating if the account opted in to forward balance changes to the rewards contract
    /// @param account Address to query
    /// @return True if balance forwarder is enabled
    function balanceForwarderEnabled(address account) external view returns (bool);

    /// @notice Enables balance forwarding for the authenticated account
    /// @dev Only the authenticated account can enable balance forwarding for itself
    /// @dev Should call the IBalanceTracker hook with the current account's balance
    function enableBalanceForwarder() external;

    /// @notice Disables balance forwarding for the authenticated account
    /// @dev Only the authenticated account can disable balance forwarding for itself
    /// @dev Should call the IBalanceTracker hook with the account's balance of 0
    function disableBalanceForwarder() external;
}

/// @title IGovernance
/// @notice Interface of the EVault's Governance module
interface IGovernance {
    /// @notice Retrieves the address of the governor
    /// @return The governor address
    function governorAdmin() external view returns (address);

    /// @notice Retrieves address of the governance fee receiver
    /// @return The fee receiver address
    function feeReceiver() external view returns (address);

    /// @notice Retrieves the interest fee in effect for the vault
    /// @return Amount of interest that is redirected as a fee, as a fraction scaled by 1e4
    function interestFee() external view returns (uint16);

    /// @notice Looks up an asset's currently configured interest rate model
    /// @return Address of the interest rate contract or address zero to indicate 0% interest
    function interestRateModel() external view returns (address);

    /// @notice Retrieves the ProtocolConfig address
    /// @return The protocol config address
    function protocolConfigAddress() external view returns (address);

    /// @notice Retrieves the protocol fee share
    /// @return A percentage share of fees accrued belonging to the protocol, in 1e4 scale
    function protocolFeeShare() external view returns (uint256);

    /// @notice Retrieves the address which will receive protocol's fees
    /// @notice The protocol fee receiver address
    function protocolFeeReceiver() external view returns (address);

    /// @notice Retrieves supply and borrow caps in AmountCap format
    /// @return supplyCap The supply cap in AmountCap format
    /// @return borrowCap The borrow cap in AmountCap format
    function caps() external view returns (uint16 supplyCap, uint16 borrowCap);

    /// @notice Retrieves the borrow LTV of the collateral, which is used to determine if the account is healthy during
    /// account status checks.
    /// @param collateral The address of the collateral to query
    /// @return Borrowing LTV in 1e4 scale
    function LTVBorrow(address collateral) external view returns (uint16);

    /// @notice Retrieves the current liquidation LTV, which is used to determine if the account is eligible for
    /// liquidation
    /// @param collateral The address of the collateral to query
    /// @return Liquidation LTV in 1e4 scale
    function LTVLiquidation(address collateral) external view returns (uint16);

    /// @notice Retrieves LTV configuration for the collateral
    /// @param collateral Collateral asset
    /// @return borrowLTV The current value of borrow LTV for originating positions
    /// @return liquidationLTV The value of fully converged liquidation LTV
    /// @return initialLiquidationLTV The initial value of the liquidation LTV, when the ramp began
    /// @return targetTimestamp The timestamp when the liquidation LTV is considered fully converged
    /// @return rampDuration The time it takes for the liquidation LTV to converge from the initial value to the fully
    /// converged value
    function LTVFull(address collateral)
        external
        view
        returns (
            uint16 borrowLTV,
            uint16 liquidationLTV,
            uint16 initialLiquidationLTV,
            uint48 targetTimestamp,
            uint32 rampDuration
        );

    /// @notice Retrieves a list of collaterals with configured LTVs
    /// @return List of asset collaterals
    /// @dev Returned assets could have the ltv disabled (set to zero)
    function LTVList() external view returns (address[] memory);

    /// @notice Retrieves the maximum liquidation discount
    /// @return The maximum liquidation discount in 1e4 scale
    /// @dev The default value, which is zero, is deliberately bad, as it means there would be no incentive to liquidate
    /// unhealthy users. The vault creator must take care to properly select the limit, given the underlying and
    /// collaterals used.
    function maxLiquidationDiscount() external view returns (uint16);

    /// @notice Retrieves liquidation cool-off time, which must elapse after successful account status check before
    /// account can be liquidated
    /// @return The liquidation cool off time in seconds
    function liquidationCoolOffTime() external view returns (uint16);

    /// @notice Retrieves a hook target and a bitmask indicating which operations call the hook target
    /// @return hookTarget Address of the hook target contract
    /// @return hookedOps Bitmask with operations that should call the hooks. See Constants.sol for a list of operations
    function hookConfig() external view returns (address hookTarget, uint32 hookedOps);

    /// @notice Retrieves a bitmask indicating enabled config flags
    /// @return Bitmask with config flags enabled
    function configFlags() external view returns (uint32);

    /// @notice Address of EthereumVaultConnector contract
    /// @return The EVC address
    function EVC() external view returns (address);

    /// @notice Retrieves a reference asset used for liquidity calculations
    /// @return The address of the reference asset
    function unitOfAccount() external view returns (address);

    /// @notice Retrieves the address of the oracle contract
    /// @return The address of the oracle
    function oracle() external view returns (address);

    /// @notice Retrieves the Permit2 contract address
    /// @return The address of the Permit2 contract
    function permit2Address() external view returns (address);

    /// @notice Splits accrued fees balance according to protocol fee share and transfers shares to the governor fee
    /// receiver and protocol fee receiver
    function convertFees() external;

    /// @notice Set a new governor address
    /// @param newGovernorAdmin The new governor address
    /// @dev Set to zero address to renounce privileges and make the vault non-governed
    function setGovernorAdmin(address newGovernorAdmin) external;

    /// @notice Set a new governor fee receiver address
    /// @param newFeeReceiver The new fee receiver address
    function setFeeReceiver(address newFeeReceiver) external;

    /// @notice Set a new LTV config
    /// @param collateral Address of collateral to set LTV for
    /// @param borrowLTV New borrow LTV, for assessing account's health during account status checks, in 1e4 scale
    /// @param liquidationLTV New liquidation LTV after ramp ends in 1e4 scale
    /// @param rampDuration Ramp duration in seconds
    function setLTV(address collateral, uint16 borrowLTV, uint16 liquidationLTV, uint32 rampDuration) external;

    /// @notice Set a new maximum liquidation discount
    /// @param newDiscount New maximum liquidation discount in 1e4 scale
    /// @dev If the discount is zero (the default), the liquidators will not be incentivized to liquidate unhealthy
    /// accounts
    function setMaxLiquidationDiscount(uint16 newDiscount) external;

    /// @notice Set a new liquidation cool off time, which must elapse after successful account status check before
    /// account can be liquidated
    /// @param newCoolOffTime The new liquidation cool off time in seconds
    /// @dev Setting cool off time to zero allows liquidating the account in the same block as the last successful
    /// account status check
    function setLiquidationCoolOffTime(uint16 newCoolOffTime) external;

    /// @notice Set a new interest rate model contract
    /// @param newModel The new IRM address
    /// @dev If the new model reverts, perhaps due to governor error, the vault will silently use a zero interest
    /// rate. Governor should make sure the new interest rates are computed as expected.
    function setInterestRateModel(address newModel) external;

    /// @notice Set a new hook target and a new bitmap indicating which operations should call the hook target.
    /// Operations are defined in Constants.sol.
    /// @param newHookTarget The new hook target address. Use address(0) to simply disable hooked operations
    /// @param newHookedOps Bitmask with the new hooked operations
    /// @dev All operations are initially disabled in a newly created vault. The vault creator must set their
    /// own configuration to make the vault usable
    function setHookConfig(address newHookTarget, uint32 newHookedOps) external;

    /// @notice Set new bitmap indicating which config flags should be enabled. Flags are defined in Constants.sol
    /// @param newConfigFlags Bitmask with the new config flags
    function setConfigFlags(uint32 newConfigFlags) external;

    /// @notice Set new supply and borrow caps in AmountCap format
    /// @param supplyCap The new supply cap in AmountCap fromat
    /// @param borrowCap The new borrow cap in AmountCap fromat
    function setCaps(uint16 supplyCap, uint16 borrowCap) external;

    /// @notice Set a new interest fee
    /// @param newFee The new interest fee
    function setInterestFee(uint16 newFee) external;
}

/// @title IEVault
/// @custom:security-contact security@euler.xyz
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Interface of the EVault, an EVC enabled lending vault
interface IEVault is
    IInitialize,
    IToken,
    IVault,
    IBorrowing,
    ILiquidation,
    IRiskManager,
    IBalanceForwarder,
    IGovernance
{
    /// @notice Fetch address of the `Initialize` module
    function MODULE_INITIALIZE() external view returns (address);
    /// @notice Fetch address of the `Token` module
    function MODULE_TOKEN() external view returns (address);
    /// @notice Fetch address of the `Vault` module
    function MODULE_VAULT() external view returns (address);
    /// @notice Fetch address of the `Borrowing` module
    function MODULE_BORROWING() external view returns (address);
    /// @notice Fetch address of the `Liquidation` module
    function MODULE_LIQUIDATION() external view returns (address);
    /// @notice Fetch address of the `RiskManager` module
    function MODULE_RISKMANAGER() external view returns (address);
    /// @notice Fetch address of the `BalanceForwarder` module
    function MODULE_BALANCE_FORWARDER() external view returns (address);
    /// @notice Fetch address of the `Governance` module
    function MODULE_GOVERNANCE() external view returns (address);
}
// SPDX--License-Identifier: GPL-2.0-or-later

/* pragma solidity >=0.8.0; */

/// @title IVault
/// @custom:security-contact security@euler.xyz
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice This interface defines the methods for the Vault for the purpose of integration with the Ethereum Vault
/// Connector.
interface IEVCVault {
    /// @notice Disables a controller (this vault) for the authenticated account.
    /// @dev A controller is a vault that has been chosen for an account to have special control over account’s
    /// balances in the enabled collaterals vaults. User calls this function in order for the vault to disable itself
    /// for the account if the conditions are met (i.e. user has repaid debt in full). If the conditions are not met,
    /// the function reverts.
    function disableController() external;

    /// @notice Checks the status of an account.
    /// @dev This function must only deliberately revert if the account status is invalid. If this function reverts due
    /// to any other reason, it may render the account unusable with possibly no way to recover funds.
    /// @param account The address of the account to be checked.
    /// @param collaterals The array of enabled collateral addresses to be considered for the account status check.
    /// @return magicValue Must return the bytes4 magic value 0xb168c58f (which is a selector of this function) when
    /// account status is valid, or revert otherwise.
    function checkAccountStatus(
        address account,
        address[] calldata collaterals
    ) external view returns (bytes4 magicValue);

    /// @notice Checks the status of the vault.
    /// @dev This function must only deliberately revert if the vault status is invalid. If this function reverts due to
    /// any other reason, it may render some accounts unusable with possibly no way to recover funds.
    /// @return magicValue Must return the bytes4 magic value 0x4b3d1223 (which is a selector of this function) when
    /// account status is valid, or revert otherwise.
    function checkVaultStatus() external returns (bytes4 magicValue);
}
// SPDX--License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/IERC20.sol)

/* pragma solidity ^0.8.20; */

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}
// SPDX--License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (utils/introspection/IERC165.sol)

/* pragma solidity ^0.8.20; */

/**
 * @dev Interface of the ERC-165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[ERC].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
// SPDX--License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (interfaces/IERC1363.sol)

/* pragma solidity ^0.8.20; */
/* import {IERC20} from "./IERC20.sol"; */
/* import {IERC165} from "./IERC165.sol"; */

/**
 * @title IERC1363
 * @dev Interface of the ERC-1363 standard as defined in the https://eips.ethereum.org/EIPS/eip-1363[ERC-1363].
 *
 * Defines an extension interface for ERC-20 tokens that supports executing code on a recipient contract
 * after `transfer` or `transferFrom`, or code on a spender contract after `approve`, in a single transaction.
 */
interface IERC1363 is IERC20, IERC165 {
    /*
     * Note: the ERC-165 identifier for this interface is 0xb0202a11.
     * 0xb0202a11 ===
     *   bytes4(keccak256('transferAndCall(address,uint256)')) ^
     *   bytes4(keccak256('transferAndCall(address,uint256,bytes)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256,bytes)'))
     */

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferAndCall(address to, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `to`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the allowance mechanism
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferFromAndCall(address from, address to, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the allowance mechanism
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `to`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferFromAndCall(address from, address to, uint256 value, bytes calldata data) external returns (bool);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens and then calls {IERC1363Spender-onApprovalReceived} on `spender`.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function approveAndCall(address spender, uint256 value) external returns (bool);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens and then calls {IERC1363Spender-onApprovalReceived} on `spender`.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @param data Additional data with no specified format, sent in call to `spender`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function approveAndCall(address spender, uint256 value, bytes calldata data) external returns (bool);
}
// SPDX--License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/utils/SafeERC20.sol)

/* pragma solidity ^0.8.20; */
/* import {IERC20} from "../IERC20.sol"; */
/* import {IERC1363} from "../../../interfaces/IERC1363.sol"; */
/* import {Address} from "../../../utils/Address.sol"; */

/**
 * @title SafeERC20
 * @dev Wrappers around ERC-20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    /**
     * @dev An operation with an ERC-20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     *
     * IMPORTANT: If the token implements ERC-7674 (ERC-20 with temporary allowance), and if the "client"
     * smart contract uses ERC-7674 to set temporary allowances, then the "client" smart contract should avoid using
     * this function. Performing a {safeIncreaseAllowance} or {safeDecreaseAllowance} operation on a token contract
     * that has a non-zero temporary allowance (for that particular owner-spender) will result in unexpected behavior.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     *
     * IMPORTANT: If the token implements ERC-7674 (ERC-20 with temporary allowance), and if the "client"
     * smart contract uses ERC-7674 to set temporary allowances, then the "client" smart contract should avoid using
     * this function. Performing a {safeIncreaseAllowance} or {safeDecreaseAllowance} operation on a token contract
     * that has a non-zero temporary allowance (for that particular owner-spender) will result in unexpected behavior.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     *
     * NOTE: If the token implements ERC-7674, this function will not modify any temporary allowance. This function
     * only sets the "standard" allowance. Any temporary allowance will remain active, in addition to the value being
     * set here.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Performs an {ERC1363} transferAndCall, with a fallback to the simple {ERC20} transfer if the target has no
     * code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * Reverts if the returned value is other than `true`.
     */
    function transferAndCallRelaxed(IERC1363 token, address to, uint256 value, bytes memory data) internal {
        if (to.code.length == 0) {
            safeTransfer(token, to, value);
        } else if (!token.transferAndCall(to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Performs an {ERC1363} transferFromAndCall, with a fallback to the simple {ERC20} transferFrom if the target
     * has no code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * Reverts if the returned value is other than `true`.
     */
    function transferFromAndCallRelaxed(
        IERC1363 token,
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) internal {
        if (to.code.length == 0) {
            safeTransferFrom(token, from, to, value);
        } else if (!token.transferFromAndCall(from, to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Performs an {ERC1363} approveAndCall, with a fallback to the simple {ERC20} approve if the target has no
     * code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * NOTE: When the recipient address (`to`) has no code (i.e. is an EOA), this function behaves as {forceApprove}.
     * Opposedly, when the recipient address (`to`) has code, this function only attempts to call {ERC1363-approveAndCall}
     * once without retrying, and relies on the returned value to be true.
     *
     * Reverts if the returned value is other than `true`.
     */
    function approveAndCallRelaxed(IERC1363 token, address to, uint256 value, bytes memory data) internal {
        if (to.code.length == 0) {
            forceApprove(token, to, value);
        } else if (!token.approveAndCall(to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturnBool} that reverts if call fails to meet the requirements.
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        uint256 returnSize;
        uint256 returnValue;
        assembly ("memory-safe") {
            let success := call(gas(), token, 0, add(data, 0x20), mload(data), 0, 0x20)
            // bubble errors
            if iszero(success) {
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }
            returnSize := returndatasize()
            returnValue := mload(0)
        }

        if (returnSize == 0 ? address(token).code.length == 0 : returnValue != 1) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silently catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly ("memory-safe") {
            success := call(gas(), token, 0, add(data, 0x20), mload(data), 0, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0)
        }
        return success && (returnSize == 0 ? address(token).code.length > 0 : returnValue == 1);
    }
}
// SPDX--License-Identifier: BUSL-1.1
/* pragma solidity ^0.8.27; */
/* import {SafeERC20, IERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol"; */
/* import {IEVault} from "evk/EVault/IEVault.sol"; */
/* import {CtxLib} from "./CtxLib.sol"; */
/* import {CurveLib} from "./CurveLib.sol"; */
/* import {FundsLib} from "./FundsLib.sol"; */
/* import {QuoteLib} from "./QuoteLib.sol"; */
/* import {EulerSwapProtocolFeeConfig} from "../EulerSwapProtocolFeeConfig.sol"; */
/* import {IEulerSwap} from "../interfaces/IEulerSwap.sol"; */
/* import "../interfaces/IEulerSwapHookTarget.sol"; */

library SwapLib {
    using SafeERC20 for IERC20;

    /// @notice Emitted after every swap.
    ///   * `sender` is the initiator of the swap, or the Router when invoked via hook.
    ///   * `amount0In` and `amount1In` are after fees have been subtracted.
    ///   * `fee0` and `fee1` are the amount of input tokens received fees.
    ///   * `reserve0` and `reserve1` are the pool's new reserves (after the swap).
    ///   * `to` is the specified recipient of the funds, or the PoolManager when invoked via hook.
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        uint256 fee0,
        uint256 fee1,
        uint112 reserve0,
        uint112 reserve1,
        address indexed to
    );

    error CurveViolation();
    error HookError(uint8 hookFlag, bytes wrappedError);

    struct SwapContext {
        // Populated by init
        address evc;
        address protocolFeeConfig;
        IEulerSwap.StaticParams sParams;
        IEulerSwap.DynamicParams dParams;
        address asset0;
        address asset1;
        address sender;
        address to;
        // Amount parameters
        uint256 amount0InFull;
        uint256 amount1InFull;
        uint256 amount0Out;
        uint256 amount1Out;
        // Internal
        uint256 amount0In; // full minus fees
        uint256 amount1In; // full minus fees
    }

    function init(address evc, address protocolFeeConfig, address sender, address to)
        internal
        view
        returns (SwapContext memory ctx)
    {
        ctx.evc = evc;
        ctx.protocolFeeConfig = protocolFeeConfig;
        ctx.sParams = CtxLib.getStaticParams();
        ctx.dParams = CtxLib.getDynamicParams();

        ctx.asset0 = IEVault(ctx.sParams.supplyVault0).asset();
        ctx.asset1 = IEVault(ctx.sParams.supplyVault1).asset();
        ctx.sender = sender;
        ctx.to = to;

        require(ctx.dParams.expiration == 0 || ctx.dParams.expiration > block.timestamp, QuoteLib.Expired());
    }

    function setAmountsOut(SwapContext memory ctx, uint256 amount0Out, uint256 amount1Out) internal pure {
        ctx.amount0Out = amount0Out;
        ctx.amount1Out = amount1Out;
    }

    function setAmountsIn(SwapContext memory ctx, uint256 amount0InFull, uint256 amount1InFull) internal pure {
        ctx.amount0InFull = amount0InFull;
        ctx.amount1InFull = amount1InFull;
    }

    function invokeBeforeSwapHook(SwapContext memory ctx) internal {
        if ((ctx.dParams.swapHookedOperations & EULER_SWAP_HOOK_BEFORE_SWAP) == 0) return;

        (bool success, bytes memory data) = ctx.dParams.swapHook.call(
            abi.encodeCall(IEulerSwapHookTarget.beforeSwap, (ctx.amount0Out, ctx.amount1Out, ctx.sender, ctx.to))
        );
        require(success, HookError(EULER_SWAP_HOOK_BEFORE_SWAP, data));
    }

    function invokeAfterSwapHook(SwapContext memory ctx, CtxLib.State storage s, uint256 fee0, uint256 fee1) internal {
        if ((ctx.dParams.swapHookedOperations & EULER_SWAP_HOOK_AFTER_SWAP) == 0) return;

        s.status = 1; // Unlock the reentrancy guard during afterSwap, allowing hook to reconfigure()

        (bool success, bytes memory data) = ctx.dParams.swapHook.call(
            abi.encodeCall(
                IEulerSwapHookTarget.afterSwap,
                (
                    ctx.amount0In,
                    ctx.amount1In,
                    ctx.amount0Out,
                    ctx.amount1Out,
                    fee0,
                    fee1,
                    ctx.sender,
                    ctx.to,
                    s.reserve0,
                    s.reserve1
                )
            )
        );
        require(success, HookError(EULER_SWAP_HOOK_AFTER_SWAP, data));

        s.status = 2;
    }

    function doDeposits(SwapContext memory ctx) internal {
        doDeposit(ctx, true);
        doDeposit(ctx, false);
    }

    function doWithdraws(SwapContext memory ctx) internal {
        doWithdraw(ctx, false);
        doWithdraw(ctx, true);
    }

    function finish(SwapContext memory ctx) internal {
        CtxLib.State storage s = CtxLib.getState();

        uint256 newReserve0 = s.reserve0 + ctx.amount0In - ctx.amount0Out;
        uint256 newReserve1 = s.reserve1 + ctx.amount1In - ctx.amount1Out;

        require(CurveLib.verify(ctx.dParams, newReserve0, newReserve1), CurveViolation());

        s.reserve0 = uint112(newReserve0);
        s.reserve1 = uint112(newReserve1);

        uint256 fee0 = ctx.amount0InFull - ctx.amount0In;
        uint256 fee1 = ctx.amount1InFull - ctx.amount1In;

        emit Swap(
            ctx.sender,
            ctx.amount0In,
            ctx.amount1In,
            ctx.amount0Out,
            ctx.amount1Out,
            fee0,
            fee1,
            s.reserve0,
            s.reserve1,
            ctx.to
        );

        invokeAfterSwapHook(ctx, s, fee0, fee1);
    }

    // Private

    function doDeposit(SwapContext memory ctx, bool asset0IsInput) private {
        uint256 amount = asset0IsInput ? ctx.amount0InFull : ctx.amount1InFull;
        if (amount == 0) return;

        address assetInput = asset0IsInput ? ctx.asset0 : ctx.asset1;

        uint256 fee = QuoteLib.getFee(ctx.dParams, asset0IsInput);
        require(fee < 1e18, QuoteLib.SwapRejected());

        uint256 feeAmount = amount * fee / 1e18;

        // Slice off protocol fee

        {
            (address protocolFeeRecipient, uint64 protocolFee) =
                EulerSwapProtocolFeeConfig(ctx.protocolFeeConfig).getProtocolFee(address(this));

            if (protocolFee != 0) {
                uint256 protocolFeeAmount = feeAmount * protocolFee / 1e18;

                if (protocolFeeAmount != 0) {
                    IERC20(assetInput).safeTransfer(protocolFeeRecipient, protocolFeeAmount);

                    amount -= protocolFeeAmount;
                    feeAmount -= protocolFeeAmount;
                }
            }
        }

        // Slice off separate LP fee recipient

        if (ctx.sParams.feeRecipient != address(0) && feeAmount != 0) {
            IERC20(assetInput).safeTransfer(ctx.sParams.feeRecipient, feeAmount);

            amount -= feeAmount;
            feeAmount = 0;
        }

        // Deposit remainder on behalf of eulerAccount

        amount = FundsLib.depositAssets(
            ctx.evc,
            ctx.sParams.eulerAccount,
            asset0IsInput ? ctx.sParams.supplyVault0 : ctx.sParams.supplyVault1,
            asset0IsInput ? ctx.sParams.borrowVault0 : ctx.sParams.borrowVault1,
            amount
        );

        amount = amount > feeAmount ? amount - feeAmount : 0;

        if (asset0IsInput) ctx.amount0In = amount;
        else ctx.amount1In = amount;
    }

    function doWithdraw(SwapContext memory ctx, bool asset0IsInput) private {
        uint256 amount = asset0IsInput ? ctx.amount1Out : ctx.amount0Out;
        if (amount == 0) return;

        FundsLib.withdrawAssets(
            ctx.evc,
            ctx.sParams.eulerAccount,
            asset0IsInput ? ctx.sParams.supplyVault1 : ctx.sParams.supplyVault0,
            asset0IsInput ? ctx.sParams.borrowVault1 : ctx.sParams.borrowVault0,
            amount,
            ctx.to
        );
    }
}
// SPDX--License-Identifier: MIT
/* pragma solidity >=0.8.0; */

uint8 constant EULER_SWAP_HOOK_BEFORE_SWAP = 1 << 0;
uint8 constant EULER_SWAP_HOOK_GET_FEE = 1 << 1;
uint8 constant EULER_SWAP_HOOK_AFTER_SWAP = 1 << 2;

interface IEulerSwapHookTarget {
    function beforeSwap(uint256 amount0Out, uint256 amount1Out, address msgSender, address to) external;

    function getFee(bool asset0IsInput, uint112 reserve0, uint112 reserve1, bool readOnly)
        external
        returns (uint64 fee);

    function afterSwap(
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        uint256 fee0,
        uint256 fee1,
        address msgSender,
        address to,
        uint112 reserve0,
        uint112 reserve1
    ) external;
}
// SPDX--License-Identifier: MIT
/* pragma solidity ^0.8.25; */
/* import {Panic} from "./Panic.sol"; */

library UnsafeMath {
    function unsafeInc(uint256 x) internal pure returns (uint256) {
        unchecked {
            return x + 1;
        }
    }

    function unsafeInc(uint256 x, bool b) internal pure returns (uint256 r) {
        assembly ("memory-safe") {
            r := add(x, b)
        }
    }

    function unsafeInc(int256 x) internal pure returns (int256) {
        unchecked {
            return x + 1;
        }
    }

    function unsafeDec(uint256 x) internal pure returns (uint256) {
        unchecked {
            return x - 1;
        }
    }

    function unsafeDec(uint256 x, bool b) internal pure returns (uint256 r) {
        assembly ("memory-safe") {
            r := sub(x, b)
        }
    }

    function unsafeDec(int256 x) internal pure returns (int256) {
        unchecked {
            return x - 1;
        }
    }

    function unsafeNeg(int256 x) internal pure returns (int256) {
        unchecked {
            return -x;
        }
    }

    function unsafeAbs(int256 x) internal pure returns (uint256 r) {
        assembly ("memory-safe") {
            r := mul(or(0x01, sar(0xff, x)), x)
        }
    }

    function unsafeDiv(uint256 numerator, uint256 denominator) internal pure returns (uint256 quotient) {
        assembly ("memory-safe") {
            quotient := div(numerator, denominator)
        }
    }

    function unsafeDiv(int256 numerator, int256 denominator) internal pure returns (int256 quotient) {
        assembly ("memory-safe") {
            quotient := sdiv(numerator, denominator)
        }
    }

    function unsafeMod(uint256 numerator, uint256 denominator) internal pure returns (uint256 remainder) {
        assembly ("memory-safe") {
            remainder := mod(numerator, denominator)
        }
    }

    function unsafeMod(int256 numerator, int256 denominator) internal pure returns (int256 remainder) {
        assembly ("memory-safe") {
            remainder := smod(numerator, denominator)
        }
    }

    function unsafeMulMod(uint256 a, uint256 b, uint256 m) internal pure returns (uint256 r) {
        assembly ("memory-safe") {
            r := mulmod(a, b, m)
        }
    }

    function unsafeAddMod(uint256 a, uint256 b, uint256 m) internal pure returns (uint256 r) {
        assembly ("memory-safe") {
            r := addmod(a, b, m)
        }
    }

    function unsafeDivUp(uint256 n, uint256 d) internal pure returns (uint256 r) {
        assembly ("memory-safe") {
            r := add(gt(mod(n, d), 0x00), div(n, d))
        }
    }

    /// rounds away from zero
    function unsafeDivUp(int256 n, int256 d) internal pure returns (int256 r) {
        assembly ("memory-safe") {
            r := add(mul(lt(0x00, smod(n, d)), or(0x01, sar(0xff, xor(n, d)))), sdiv(n, d))
        }
    }

    function unsafeAdd(uint256 a, uint256 b) internal pure returns (uint256 r) {
        assembly ("memory-safe") {
            r := add(a, b)
        }
    }
}

library Math {
    function inc(uint256 x, bool c) internal pure returns (uint256 r) {
        assembly ("memory-safe") {
            r := add(x, c)
        }
        if (r < x) {
            Panic.panic(Panic.ARITHMETIC_OVERFLOW);
        }
    }

    function dec(uint256 x, bool c) internal pure returns (uint256 r) {
        assembly ("memory-safe") {
            r := sub(x, c)
        }
        if (r > x) {
            Panic.panic(Panic.ARITHMETIC_OVERFLOW);
        }
    }

    function toInt(bool c) internal pure returns (uint256 r) {
        assembly ("memory-safe") {
            r := c
        }
    }

    function saturatingAdd(uint256 x, uint256 y) internal pure returns (uint256 r) {
        assembly ("memory-safe") {
            r := add(x, y)
            r := or(r, sub(0x00, lt(r, y)))
        }
    }

    function saturatingSub(uint256 x, uint256 y) internal pure returns (uint256 r) {
        assembly ("memory-safe") {
            r := mul(gt(x, y), sub(x, y))
        }
    }

    function absDiff(uint256 x, uint256 y) internal pure returns (uint256 r, bool sign) {
        assembly ("memory-safe") {
            sign := lt(x, y)
            let m := sub(0x00, sign)
            r := sub(xor(sub(x, y), m), m)
        }
    }
}
// SPDX--License-Identifier: MIT
/* pragma solidity ^0.8.25; */

library Panic {
    function panic(uint256 code) internal pure {
        assembly ("memory-safe") {
            mstore(0x00, 0x4e487b71) // selector for `Panic(uint256)`
            mstore(0x20, code)
            revert(0x1c, 0x24)
        }
    }

    // https://docs.soliditylang.org/en/latest/control-structures.html#panic-via-assert-and-error-via-require
    uint8 internal constant GENERIC = 0x00;
    uint8 internal constant ASSERT_FAIL = 0x01;
    uint8 internal constant ARITHMETIC_OVERFLOW = 0x11;
    uint8 internal constant DIVISION_BY_ZERO = 0x12;
    uint8 internal constant ENUM_CAST = 0x21;
    uint8 internal constant CORRUPT_STORAGE_ARRAY = 0x22;
    uint8 internal constant POP_EMPTY_ARRAY = 0x31;
    uint8 internal constant ARRAY_OUT_OF_BOUNDS = 0x32;
    uint8 internal constant OUT_OF_MEMORY = 0x41;
    uint8 internal constant ZERO_FUNCTION_POINTER = 0x51;
}
// SPDX--License-Identifier: MIT
/* pragma solidity ^0.8.25; */
/* import {UnsafeMath, Math} from "./UnsafeMath.sol"; */
/* import {Panic} from "./Panic.sol"; */

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
/// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
library FullMath {
    using UnsafeMath for uint256;
    using UnsafeMath for uint8;
    using Math for uint256;
    using Math for bool;

    /// @notice 512-bit multiply [prod1 prod0] = a * b
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @return lo Least significant 256 bits of the product
    /// @return hi Most significant 256 bits of the product
    function fullMul(uint256 a, uint256 b) internal pure returns (uint256 lo, uint256 hi) {
        // Compute the product mod 2**256 and mod 2**256 - 1 then use the Chinese
        // Remainder Theorem to reconstruct the 512 bit result. The result is stored
        // in two 256 variables such that product = prod1 * 2**256 + prod0
        assembly ("memory-safe") {
            let mm := mulmod(a, b, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            lo := mul(a, b)
            hi := sub(sub(mm, lo), lt(mm, lo))
        }
    }

    function fullLt(uint256 a_lo, uint256 a_hi, uint256 b_lo, uint256 b_hi) internal pure returns (bool r) {
        assembly ("memory-safe") {
            r := or(lt(a_hi, b_hi), and(eq(a_hi, b_hi), lt(a_lo, b_lo)))
        }
    }

    /// @notice 512-bit multiply [prod1 prod0] = a * b
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return prod0 Least significant 256 bits of the product
    /// @return prod1 Most significant 256 bits of the product
    /// @return remainder Remainder of full-precision division
    function _mulDivSetup(uint256 a, uint256 b, uint256 denominator)
        private
        pure
        returns (uint256 prod0, uint256 prod1, uint256 remainder)
    {
        (prod0, prod1) = fullMul(a, b);
        remainder = a.unsafeMulMod(b, denominator);
    }

    /// @notice 512-bit by 256-bit division.
    /// @param prod0 Least significant 256 bits of the product
    /// @param prod1 Most significant 256 bits of the product
    /// @param denominator The divisor
    /// @param remainder Remainder of full-precision division
    /// @return The 256-bit result
    /// @dev Overflow and division by zero aren't checked and are GIGO errors
    function _mulDivInvert(uint256 prod0, uint256 prod1, uint256 denominator, uint256 remainder)
        private
        pure
        returns (uint256)
    {
        uint256 inv;
        assembly ("memory-safe") {
            // Make division exact by rounding [prod1 prod0] down to a multiple of
            // denominator
            // Subtract 256 bit number from 512 bit number
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)

            // Factor powers of two out of denominator
            {
                // Compute largest power of two divisor of denominator.
                // Always >= 1.
                let twos := and(sub(0, denominator), denominator)

                // Divide denominator by power of two
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by the factors of two
                prod0 := div(prod0, twos)
                // Shift in bits from prod1 into prod0. For this we need to flip `twos`
                // such that it is 2**256 / twos.
                // If twos is zero, then it becomes one
                twos := add(div(sub(0, twos), twos), 1)
                prod0 := or(prod0, mul(prod1, twos))
            }

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse modulo 2**256
            // such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct correct for
            // four bits. That is, denominator * inv = 1 mod 2**4
            inv := xor(mul(3, denominator), 2)

            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**8
            inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**16
            inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**32
            inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**64
            inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**128
            inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**256
        }

        // Because the division is now exact we can divide by multiplying with the
        // modular inverse of denominator. This will give us the correct result
        // modulo 2**256. Since the precoditions guarantee that the outcome is less
        // than 2**256, this is the final result.  We don't need to compute the high
        // bits of the result and prod1 is no longer required.
        unchecked {
            return prod0 * inv;
        }
    }

    /// @notice Calculates a×b÷denominator with full precision then rounds towards 0. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return The 256-bit result
    function mulDiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256) {
        (uint256 prod0, uint256 prod1, uint256 remainder) = _mulDivSetup(a, b, denominator);
        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        if (denominator <= prod1) {
            unchecked {
                Panic.panic(Panic.ARITHMETIC_OVERFLOW.unsafeInc(denominator == 0));
            }
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            return prod0.unsafeDiv(denominator);
        }
        return _mulDivInvert(prod0, prod1, denominator, remainder);
    }

    /// @notice Calculates a×b÷denominator with full precision then rounds towards positive infinity. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return The 256-bit result
    function mulDivUp(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256) {
        (uint256 prod0, uint256 prod1, uint256 remainder) = _mulDivSetup(a, b, denominator);
        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        if (denominator <= prod1) {
            unchecked {
                Panic.panic(Panic.ARITHMETIC_OVERFLOW.unsafeInc(denominator == 0));
            }
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            return prod0.unsafeDivUp(denominator);
        }
        return _mulDivInvert(prod0, prod1, denominator, remainder).inc(0 < remainder);
    }

    /// @notice Calculates a×b÷denominator with full precision then rounds towards positive infinity. Returns `type(uint256).max` if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return The 256-bit result
    function saturatingMulDivUp(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256) {
        (uint256 prod0, uint256 prod1, uint256 remainder) = _mulDivSetup(a, b, denominator);
        uint256 overflow;
        unchecked {
            overflow = (denominator > prod1).toInt() - 1;
        }
        if (prod1 == 0) {
            return prod0.unsafeDivUp(denominator).saturatingAdd(overflow);
        }
        return _mulDivInvert(prod0, prod1, denominator, remainder).inc(0 < remainder).saturatingAdd(overflow);
    }

    /// @notice Calculates a×b÷denominator with full precision then rounds towards 0. Overflowing a uint256 or denominator == 0 are GIGO errors
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return The 256-bit result
    function unsafeMulDiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256) {
        (uint256 prod0, uint256 prod1, uint256 remainder) = _mulDivSetup(a, b, denominator);
        // Overflow and zero-division checks are skipped
        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            return prod0.unsafeDiv(denominator);
        }
        return _mulDivInvert(prod0, prod1, denominator, remainder);
    }

    /// @notice Calculates a×b÷denominator with full precision then rounds towards 0. Overflowing a uint256 or denominator == 0 are GIGO errors
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @dev This is the branchless, straight line version of `unsafeMulDiv`. If we know that `prod1 != 0` this may be faster. Also this gives Solc a better chance to optimize.
    /// @return The 256-bit result
    function unsafeMulDivAlt(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256) {
        (uint256 prod0, uint256 prod1, uint256 remainder) = _mulDivSetup(a, b, denominator);
        return _mulDivInvert(prod0, prod1, denominator, remainder);
    }

    /// @notice Calculates a×b÷denominator with full precision then rounds towards positive infinity. Overflowing a uint256 or denominator == 0 are GIGO errors
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return The 256-bit result
    function unsafeMulDivUp(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256) {
        (uint256 prod0, uint256 prod1, uint256 remainder) = _mulDivSetup(a, b, denominator);
        // Overflow and zero-division checks are skipped
        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            return prod0.unsafeDivUp(denominator);
        }
        return _mulDivInvert(prod0, prod1, denominator, remainder).unsafeInc(0 < remainder);
    }

    /// @notice Calculates a×b÷denominator with full precision then rounds towards positive infinity. Overflowing a uint256 or denominator == 0 are GIGO errors
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @dev This is the branchless, straight line version of `unsafeMulDivUp`. If we know that `prod1 != 0` this may be faster. Also this gives Solc a better chance to optimize.
    /// @return The 256-bit result
    function unsafeMulDivUpAlt(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256) {
        (uint256 prod0, uint256 prod1, uint256 remainder) = _mulDivSetup(a, b, denominator);
        return _mulDivInvert(prod0, prod1, denominator, remainder).unsafeInc(0 < remainder);
    }

    function unsafeMulShift(uint256 a, uint256 b, uint256 s) internal pure returns (uint256 result) {
        assembly ("memory-safe") {
            let mm := mulmod(a, b, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            let prod0 := mul(a, b)
            let prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            result := or(shr(s, prod0), shl(sub(0x100, s), prod1))
        }
    }

    function unsafeMulShiftUp(uint256 a, uint256 b, uint256 s) internal pure returns (uint256 result) {
        assembly ("memory-safe") {
            let mm := mulmod(a, b, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            let prod0 := mul(a, b)
            let prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            let s_ := sub(0x100, s)
            result := or(shr(s, prod0), shl(s_, prod1))
            result := add(lt(0x00, shl(s_, prod0)), result)
        }
    }
}
// SPDX--License-Identifier: MIT
/* pragma solidity ^0.8.25; */

// @author Modified from Solady by Vectorized https://github.com/Vectorized/solady/blob/701406e8126cfed931645727b274df303fbcd94d/src/utils/LibBit.sol#L30-L45 under the MIT license
library Clz {
    /// @dev Count leading zeros.
    /// Returns the number of zeros preceding the most significant one bit.
    /// If `x` is zero, returns 256.
    function clz(uint256 x) internal pure returns (uint256 r) {
        assembly ("memory-safe") {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            // We use a 5-bit deBruijn Sequence to convert `x`'s 8
            // most-significant bits into an index. We then index the lookup
            // table (bytewise) by the deBruijn symbol to obtain the bitwise
            // inverse of its logarithm.
            r :=
                add(
                    xor(
                        r,
                        byte(
                            and(0x1f, shr(shr(r, x), 0x8421084210842108cc6318c6db6d54be)),
                            0xf8f9f9faf9fdfafbf9fdfcfdfafbfcfef9fafdfafcfcfbfefafafcfbffffffff
                        )
                    ),
                    iszero(x)
                )
        }
    }

    function bitLength(uint256 x) internal pure returns (uint256) {
        unchecked {
            return 256 - clz(x);
        }
    }
}
// SPDX--License-Identifier: MIT
/* pragma solidity ^0.8.25; */

// @author Modified from Solady by Vectorized https://github.com/Vectorized/solady/blob/701406e8126cfed931645727b274df303fbcd94d/src/utils/FixedPointMathLib.sol#L774-L826 under the MIT license.
library Sqrt {
    /// @dev Returns the square root of `x`, rounded down.
    function _sqrt(uint256 x) private pure returns (uint256 z) {
        assembly ("memory-safe") {
            // `floor(sqrt(2**15)) = 181`. `sqrt(2**15) - 181 = 2.84`.
            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // Let `y = x / 2**r`. We check `y >= 2**(k + 8)`
            // but shift right by `k` bits to ensure that if `x >= 256`, then `y >= 256`.
            let r := shl(7, lt(0xffffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffffff, shr(r, x))))
            z := shl(shr(1, r), z)

            // Goal was to get `z*z*y` within a small factor of `x`. More iterations could
            // get y in a tighter range. Currently, we will have y in `[256, 256*(2**16))`.
            // We ensured `y >= 256` so that the relative difference between `y` and `y+1` is small.
            // That's not possible if `x < 256` but we can just verify those cases exhaustively.

            // Now, `z*z*y <= x < z*z*(y+1)`, and `y <= 2**(16+8)`, and either `y >= 256`, or `x < 256`.
            // Correctness can be checked exhaustively for `x < 256`, so we assume `y >= 256`.
            // Then `z*sqrt(y)` is within `sqrt(257)/sqrt(256)` of `sqrt(x)`, or about 20bps.

            // For `s` in the range `[1/256, 256]`, the estimate `f(s) = (181/1024) * (s+1)`
            // is in the range `(1/2.84 * sqrt(s), 2.84 * sqrt(s))`,
            // with largest error when `s = 1` and when `s = 256` or `1/256`.

            // Since `y` is in `[256, 256*(2**16))`, let `a = y/65536`, so that `a` is in `[1/256, 256)`.
            // Then we can estimate `sqrt(y)` using
            // `sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2**18`.

            // There is no overflow risk here since `y < 2**136` after the first branch above.
            z := shr(18, mul(z, add(shr(r, x), 65536))) // A `mul()` is saved from starting `z` at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
        }
    }

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        z = _sqrt(x);
        assembly ("memory-safe") {
            // If `x+1` is a perfect square, the Babylonian method cycles between
            // `floor(sqrt(x))` and `ceil(sqrt(x))`. This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            z := sub(z, lt(div(x, z), z))
        }
    }

    function sqrtUp(uint256 x) internal pure returns (uint256 z) {
        z = _sqrt(x);
        assembly ("memory-safe") {
            z := add(lt(mul(z, z), x), z)
        }
    }
}
// SPDX--License-Identifier: MIT
/* pragma solidity ^0.8.25; */

library FastLogic {
    function or(bool a, bool b) internal pure returns (bool r) {
        assembly ("memory-safe") {
            r := or(a, b)
        }
    }

    function and(bool a, bool b) internal pure returns (bool r) {
        assembly ("memory-safe") {
            r := and(a, b)
        }
    }

    function andNot(bool a, bool b) internal pure returns (bool r) {
        assembly ("memory-safe") {
            r := gt(a, b)
        }
    }
}
// SPDX--License-Identifier: BUSL-1.1

// Copyright (c) 2024-2025 Euler Labs Ltd
// Copyright (c) 2024-2025 ZeroEx Inc

// The routines in this file were optimised and improved by Duncan Townsend
// and Lazaro Raul Iglesias Vera from ZeroEx Inc. Their work is MIT licensed
// and is used here with their permission.

/* pragma solidity ^0.8.27; */
/* import {UnsafeMath, Math} from "../math/UnsafeMath.sol"; */
/* import {FullMath} from "../math/FullMath.sol"; */
/* import {FastLogic} from "../math/FastLogic.sol"; */
/* import {Clz} from "../math/Clz.sol"; */
/* import {Sqrt} from "../math/Sqrt.sol"; */
/* import {IEulerSwap} from "../interfaces/IEulerSwap.sol"; */

library CurveLib {
    using UnsafeMath for uint256;
    using UnsafeMath for int256;
    using Math for uint256;
    using FullMath for uint256;
    using Clz for uint256;
    using Sqrt for uint256;
    using FastLogic for bool;

    /// @notice Returns true if the specified reserve amounts would be acceptable, false otherwise.
    /// Acceptable points are on, or above and to-the-right of the swapping curve.
    function verify(IEulerSwap.DynamicParams memory p, uint256 newReserve0, uint256 newReserve1)
        internal
        pure
        returns (bool)
    {
        if (newReserve0 > type(uint112).max || newReserve1 > type(uint112).max) return false;
        if (newReserve0 < p.minReserve0 || newReserve1 < p.minReserve1) return false;

        if (newReserve0 >= p.equilibriumReserve0) {
            if (newReserve1 >= p.equilibriumReserve1) return true;
            return newReserve0
                >= f(newReserve1, p.priceY, p.priceX, p.equilibriumReserve1, p.equilibriumReserve0, p.concentrationY);
        } else {
            if (newReserve1 < p.equilibriumReserve1) return false;
            return newReserve1
                >= f(newReserve0, p.priceX, p.priceY, p.equilibriumReserve0, p.equilibriumReserve1, p.concentrationX);
        }
    }

    /// @dev EulerSwap curve
    /// @notice Computes the output `y` for a given input `x`.
    /// @param x The input reserve value, constrained to 1 <= x <= x0.
    /// @param px (1 <= px <= 1e25).
    /// @param py (1 <= py <= 1e25).
    /// @param x0 (1 <= x0 <= 2^112 - 1).
    /// @param y0 (0 <= y0 <= 2^112 - 1).
    /// @param c (0 <= c <= 1e18).
    /// @return y The output reserve value corresponding to input `x`, guaranteed to satisfy `y0 <= y <= 2^112 - 1`, or `type(uint256).max` on overflow.
    function f(uint256 x, uint256 px, uint256 py, uint256 x0, uint256 y0, uint256 c) internal pure returns (uint256) {
        uint256 output;

        unchecked {
            if (c == 1e18) {
                // `c == 1e18` indicates that this is a constant-sum curve. Convert `x` into `y`
                // using `px` and `py`
                uint256 v = ((x0 - x) * px).unsafeDivUp(py); // scale: 1; units: token Y
                output = y0 + v;
            } else {
                uint256 a = px * (x0 - x); // scale: 1e18; units: none; range: 196 bits
                uint256 b = c * x + (1e18 - c) * x0; // scale: 1e18; units: token X; range: 172 bits
                uint256 d = 1e18 * x * py; // scale: 1e36; units: token X / token Y; range: 255 bits
                uint256 v = a.saturatingMulDivUp(b, d); // scale: 1; units: token Y
                output = y0.saturatingAdd(v);
            }

            if (output > type(uint112).max) return type(uint256).max;
        }

        return output;
    }

    /// @dev EulerSwap inverse curve
    /// @dev Implements equations 23 through 27 from the whitepaper.
    /// @notice Computes the output `x` for a given input `y`.
    /// @notice The combination `x0 == 0 && cx < 1e18` is invalid.
    /// @param y The input reserve value, constrained to `y0 <= y <= 2^112 - 1`. (An amount of tokens in base units.)
    /// @param px (1 <= px <= 1e25). A fixnum with a basis of 1e18.
    /// @param py (1 <= py <= 1e25). A fixnum with a basis of 1e18.
    /// @param x0 (0 <= x0 <= 2^112 - 1). An amount of tokens in base units.
    /// @param y0 (0 <= y0 <= 2^112 - 1). An amount of tokens in base units.
    /// @param cx (0 <= cx <= 1e18). A fixnum with a basis of 1e18.
    /// @return x The output reserve value corresponding to input `y`, guaranteed to satisfy `0 <= x <= x0`. (An amount of tokens in base units.)
    /// @dev The maximum possible error (overestimate only) in `x` from the smallest such value that will still pass `verify` is 1 wei.
    function fInverse(uint256 y, uint256 px, uint256 py, uint256 x0, uint256 y0, uint256 cx)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            // The value `B` is implicitly computed as:
            //     [(y - y0) * py * 1e18 - (cx * 2 - 1e18) * x0 * px] / px
            // We only care about the absolute value of `B` for use later, so we separately extract
            // the sign of `B` and its absolute value
            bool sign; // `true` when `B` is negative
            uint256 absB; // scale: 1e18; units: token X; range: 255 bits
            {
                uint256 term1 = 1e18 * ((y - y0) * py + x0 * px); // scale: 1e36; units: none; range: 256 bits
                uint256 term2 = (cx << 1) * x0 * px; // scale: 1e36; units: none; range: 256 bits

                // Ensure that the result will be positive
                uint256 difference; // scale: 1e36; units: none; range: 256 bits
                (difference, sign) = term1.absDiff(term2);

                // If `sign` is true, then we want to round up. Compute the carry bit
                bool carry = (0 < difference.unsafeMod(px)).and(sign);
                absB = difference.unsafeDiv(px).unsafeInc(carry);
            }

            // `twoShift` is how much we need to shift right (the log of the scaling factor) to
            // prevent overflow when computing `squaredB`, `fourAC`, or `discriminant`. `shift` is
            // half that; the amount we have to shift left by after taking the square root of
            // `discriminant` to get back to a basis of 1e18
            uint256 shift;
            {
                uint256 shiftSquaredB = absB.bitLength().saturatingSub(127);
                // 3814697265625 is 5e17 with all the trailing zero bits removed to make the
                // constant smaller. The argument of `saturatingSub` is reduced to compensate
                uint256 shiftFourAc = (x0 * 3814697265625).bitLength().saturatingSub(109);
                shift = shiftSquaredB < shiftFourAc ? shiftFourAc : shiftSquaredB;
            }
            uint256 twoShift = shift << 1;

            uint256 x; // scale: 1; units: token X; range: 113 bits
            if (sign) {
                // `B` is negative; use the regular quadratic formula; everything rounds up.
                //     (-b + sqrt(b^2 - 4ac)) / 2a
                // Because `B` is negative, `absB == -B`; we can avoid negation.

                // `fourAC` is actually the value $-4ac$ from the "normal" conversion of the
                // constant function to its quadratic form. Computing it like this means we can
                // avoid subtraction (and potential underflow)
                uint256 fourAC = (cx * (1e18 - cx) << 2).unsafeMulShiftUp(x0 * x0, twoShift); // scale: 1e36 >> twoShift; units: (token X)^2; range: 254 bits

                uint256 squaredB = absB.unsafeMulShiftUp(absB, twoShift); // scale: 1e36 >> twoShift; units: (token X)^2; range: 254 bits
                uint256 discriminant = squaredB + fourAC; // scale: 1e36 >> twoShift; units: (token X)^2; range: 254 bits
                uint256 sqrt = discriminant.sqrtUp() << shift; // scale: 1e18; units: token X; range: 172 bits

                x = (absB + sqrt).unsafeDivUp(cx << 1);
            } else {
                // `B` is nonnegative; use the "citardauq" quadratic formula; everything except the
                // final division rounds down.
                //     2c / (-b - sqrt(b^2 - 4ac))

                // `fourAC` is actually the value $-4ac$ from the "normal" conversion of the
                // constant function to its quadratic form. Therefore, we can avoid negation of
                // `absB` and both subtractions
                uint256 fourAC = (cx * (1e18 - cx) << 2).unsafeMulShift(x0 * x0, twoShift); // scale: 1e36 >> twoShift; units: (token X)^2; range: 254 bits

                uint256 squaredB = absB.unsafeMulShift(absB, twoShift); // scale: 1e36 >> twoShift; units: (token X)^2; range: 254 bits
                uint256 discriminant = squaredB + fourAC; // scale: 1e36 >> twoShift; units: (token X)^2; range: 255 bits
                uint256 sqrt = discriminant.sqrt() << shift; // scale: 1e18; units: token X; range: 255 bits

                // If `cx == 1e18` and `B == 0`, we evaluate `0 / 0`, which is `0` on the EVM. This
                // just so happens to be the correct answer
                x = ((1e18 - cx) << 1).unsafeMulDivUpAlt(x0 * x0, absB + sqrt);
            }

            // Handle any rounding error that could produce a value out of the bounds established by
            // the NatSpec
            return x.unsafeDec(x > x0);
        }
    }
}
// SPDX--License-Identifier: BUSL-1.1
/* pragma solidity ^0.8.27; */
/* import {IEVC} from "evc/interfaces/IEthereumVaultConnector.sol"; */
/* import {IEVault} from "evk/EVault/IEVault.sol"; */
/* import {IEulerSwap} from "../interfaces/IEulerSwap.sol"; */
/* import "../interfaces/IEulerSwapHookTarget.sol"; */
/* import {CtxLib} from "./CtxLib.sol"; */
/* import {CurveLib} from "./CurveLib.sol"; */
/* import {SwapLib} from "./SwapLib.sol"; */

library QuoteLib {
    error HookError();
    error UnsupportedPair();
    error OperatorNotInstalled();
    error SwapLimitExceeded();
    error SwapRejected();
    error Expired();

    function getFee(IEulerSwap.DynamicParams memory dParams, bool asset0IsInput) internal returns (uint64 fee) {
        fee = type(uint64).max;

        if ((dParams.swapHookedOperations & EULER_SWAP_HOOK_GET_FEE) != 0) {
            CtxLib.State storage s = CtxLib.getState();

            (bool success, bytes memory data) = dParams.swapHook.call(
                abi.encodeCall(IEulerSwapHookTarget.getFee, (asset0IsInput, s.reserve0, s.reserve1, false))
            );
            require(success && data.length >= 32, SwapLib.HookError(EULER_SWAP_HOOK_GET_FEE, data));
            fee = abi.decode(data, (uint64));
        }

        if (fee == type(uint64).max) fee = asset0IsInput ? dParams.fee0 : dParams.fee1;
    }

    function getFeeReadOnly(IEulerSwap.DynamicParams memory dParams, bool asset0IsInput)
        internal
        view
        returns (uint64 fee)
    {
        fee = type(uint64).max;

        if ((dParams.swapHookedOperations & EULER_SWAP_HOOK_GET_FEE) != 0) {
            CtxLib.State storage s = CtxLib.getState();

            (bool success, bytes memory data) = dParams.swapHook.staticcall(
                abi.encodeCall(IEulerSwapHookTarget.getFee, (asset0IsInput, s.reserve0, s.reserve1, true))
            );
            require(success && data.length >= 32, SwapLib.HookError(EULER_SWAP_HOOK_GET_FEE, data));
            fee = abi.decode(data, (uint64));
        }

        if (fee == type(uint64).max) fee = asset0IsInput ? dParams.fee0 : dParams.fee1;
    }

    /// @dev Computes the quote for a swap by applying fees and validating state conditions
    /// @param evc EVC instance
    /// @param sParams Static params
    /// @param dParams Dynamic params
    /// @param asset0IsInput Swap direction
    /// @param amount The amount to quote (input amount if exactIn=true, output amount if exactIn=false)
    /// @param exactIn True if quoting for exact input amount, false if quoting for exact output amount
    /// @return The quoted amount (output amount if exactIn=true, input amount if exactIn=false)
    /// @dev Validates:
    ///      - EulerSwap operator is installed
    ///      - Token pair is supported
    ///      - Sufficient reserves exist
    ///      - Sufficient cash is available
    function computeQuote(
        address evc,
        IEulerSwap.StaticParams memory sParams,
        IEulerSwap.DynamicParams memory dParams,
        bool asset0IsInput,
        uint256 amount,
        bool exactIn
    ) internal view returns (uint256) {
        if (amount == 0) return 0;

        require(amount <= type(uint112).max, SwapLimitExceeded());

        require(IEVC(evc).isAccountOperatorAuthorized(sParams.eulerAccount, address(this)), OperatorNotInstalled());
        require(dParams.expiration == 0 || dParams.expiration > block.timestamp, Expired());

        uint256 fee = getFeeReadOnly(dParams, asset0IsInput);
        require(fee < 1e18, SwapRejected());

        (uint256 inLimit, uint256 outLimit) = calcLimits(sParams, dParams, asset0IsInput, fee);

        // exactIn: decrease effective amountIn
        if (exactIn) amount = amount - (amount * fee / 1e18);

        uint256 quote = findCurvePoint(dParams, amount, exactIn, asset0IsInput);

        if (exactIn) {
            // if `exactIn`, `quote` is the amount of assets to buy from the AMM
            require(amount <= inLimit && quote <= outLimit, SwapLimitExceeded());
        } else {
            // if `!exactIn`, `amount` is the amount of assets to buy from the AMM
            require(amount <= outLimit && quote <= inLimit, SwapLimitExceeded());

            // exactOut: inflate required amountIn
            quote = (quote * 1e18) / (1e18 - fee);
        }

        return quote;
    }

    /// @notice Calculates the maximum input and output amounts for a swap based on protocol constraints
    /// @dev Determines limits by checking multiple factors:
    ///      1. Supply caps and existing debt for the input token
    ///      2. Available reserves in the EulerSwap for the output token
    ///      3. Available cash and borrow caps for the output token
    ///      4. Account balances in the respective vaults
    /// @param sParams Static params
    /// @param dParams Dynamic params
    /// @param asset0IsInput Boolean indicating whether asset0 (true) or asset1 (false) is the input token
    /// @param fee Amount of fee required for this swap
    /// @return uint256 Maximum amount of input token that can be deposited
    /// @return uint256 Maximum amount of output token that can be withdrawn
    function calcLimits(
        IEulerSwap.StaticParams memory sParams,
        IEulerSwap.DynamicParams memory dParams,
        bool asset0IsInput,
        uint256 fee
    ) internal view returns (uint256, uint256) {
        CtxLib.State storage s = CtxLib.getState();

        uint256 inLimit = type(uint112).max;
        uint256 outLimit = type(uint112).max;

        address eulerAccount = sParams.eulerAccount;

        // Supply caps on input
        {
            IEVault supplyVault = IEVault(asset0IsInput ? sParams.supplyVault0 : sParams.supplyVault1);
            IEVault borrowVault = IEVault(asset0IsInput ? sParams.borrowVault0 : sParams.borrowVault1);
            uint256 maxDeposit = supplyVault.maxDeposit(eulerAccount);
            if (address(borrowVault) != address(0)) maxDeposit += borrowVault.debtOf(eulerAccount);
            if (maxDeposit < inLimit) inLimit = maxDeposit;
        }

        // Remaining reserves of output
        {
            uint112 reserveLimit =
                asset0IsInput ? (s.reserve1 - dParams.minReserve1) : (s.reserve0 - dParams.minReserve0);
            if (reserveLimit < outLimit) outLimit = reserveLimit;
        }

        // Remaining cash and borrow caps in output
        {
            IEVault supplyVault = IEVault(asset0IsInput ? sParams.supplyVault1 : sParams.supplyVault0);
            IEVault borrowVault = IEVault(asset0IsInput ? sParams.borrowVault1 : sParams.borrowVault0);
            uint256 supplyBalance = supplyVault.convertToAssets(supplyVault.balanceOf(eulerAccount));

            {
                uint256 supplyCash = supplyVault.cash();
                if (supplyBalance > supplyCash || supplyVault == borrowVault) {
                    // Cash in supplyVault is limiting factor
                    if (supplyCash < outLimit) outLimit = supplyCash;
                } else {
                    // Sufficient cash to cover full withdrawal, so limiting factor is cash in borrowVault
                    uint256 cashLimit = supplyBalance;
                    if (address(borrowVault) != address(0)) cashLimit += borrowVault.cash();
                    if (cashLimit < outLimit) outLimit = cashLimit;
                }
            }

            if (address(borrowVault) != address(0)) {
                (, uint16 borrowCapEncoded) = borrowVault.caps();
                uint256 borrowCap = decodeCap(uint256(borrowCapEncoded));
                if (borrowCap != type(uint256).max) {
                    uint256 totalBorrows = borrowVault.totalBorrows();
                    uint256 maxWithdraw = supplyBalance + (totalBorrows > borrowCap ? 0 : borrowCap - totalBorrows);
                    if (maxWithdraw < outLimit) outLimit = maxWithdraw;
                }
            }
        }

        {
            uint256 inLimit2 = findCurvePoint(dParams, outLimit, false, asset0IsInput);

            if (inLimit2 <= type(uint112).max) {
                if (inLimit2 < inLimit) inLimit = inLimit2 * 1e18 / (1e18 - fee);
            } else {
                uint256 outLimit2 = findCurvePoint(dParams, inLimit * (1e18 - fee) / 1e18, true, asset0IsInput);
                if (outLimit2 < outLimit) {
                    outLimit = outLimit2;
                    inLimit2 = findCurvePoint(dParams, outLimit, false, asset0IsInput) * 1e18 / (1e18 - fee);
                    if (inLimit2 < inLimit) inLimit = inLimit2;
                }
            }
        }

        return (inLimit, outLimit);
    }

    /// @notice Decodes a compact-format cap value to its actual numerical value
    /// @dev The cap uses a compact-format where:
    ///      - If amountCap == 0, there's no cap (returns max uint256)
    ///      - Otherwise, the lower 6 bits represent the exponent (10^exp)
    ///      - The upper bits (>> 6) represent the mantissa
    ///      - The formula is: (10^exponent * mantissa) / 100
    /// @param amountCap The compact-format cap value to decode
    /// @return The actual numerical cap value (type(uint256).max if uncapped)
    /// @custom:security Uses unchecked math for gas optimization as calculations cannot overflow:
    ///                  maximum possible value 10^(2^6-1) * (2^10-1) ≈ 1.023e+66 < 2^256
    function decodeCap(uint256 amountCap) internal pure returns (uint256) {
        if (amountCap == 0) return type(uint256).max;

        unchecked {
            // Cannot overflow because this is less than 2**256:
            //   10**(2**6 - 1) * (2**10 - 1) = 1.023e+66
            return 10 ** (amountCap & 63) * (amountCap >> 6) / 100;
        }
    }

    /// @notice Verifies that the given tokens are supported by the EulerSwap pool and determines swap direction
    /// @dev Returns a boolean indicating whether the input token is asset0 (true) or asset1 (false)
    /// @param sParams Static params
    /// @param tokenIn The input token address for the swap
    /// @param tokenOut The output token address for the swap
    /// @return asset0IsInput True if tokenIn is asset0 and tokenOut is asset1, false if reversed
    /// @custom:error UnsupportedPair Thrown if the token pair is not supported by the EulerSwap pool
    function checkTokens(IEulerSwap.StaticParams memory sParams, address tokenIn, address tokenOut)
        internal
        view
        returns (bool asset0IsInput)
    {
        address asset0 = IEVault(sParams.supplyVault0).asset();
        address asset1 = IEVault(sParams.supplyVault1).asset();

        if (tokenIn == asset0 && tokenOut == asset1) asset0IsInput = true;
        else if (tokenIn == asset1 && tokenOut == asset0) asset0IsInput = false;
        else revert UnsupportedPair();
    }

    function findCurvePoint(IEulerSwap.DynamicParams memory dParams, uint256 amount, bool exactIn, bool asset0IsInput)
        internal
        view
        returns (uint256 output)
    {
        CtxLib.State storage s = CtxLib.getState();
        uint112 reserve0 = s.reserve0;
        uint112 reserve1 = s.reserve1;

        uint256 px = dParams.priceX;
        uint256 py = dParams.priceY;
        uint256 x0 = dParams.equilibriumReserve0;
        uint256 y0 = dParams.equilibriumReserve1;
        uint256 cx = dParams.concentrationX;
        uint256 cy = dParams.concentrationY;

        uint256 xNew;
        uint256 yNew;

        if (exactIn) {
            // exact in
            if (asset0IsInput) {
                // swap X in and Y out
                xNew = reserve0 + amount;
                if (xNew <= x0) {
                    // remain on f()
                    yNew = CurveLib.f(xNew, px, py, x0, y0, cx);
                } else {
                    // move to g()
                    yNew = CurveLib.fInverse(xNew, py, px, y0, x0, cy);
                }
                output = reserve1 > yNew ? reserve1 - yNew : 0;
            } else {
                // swap Y in and X out
                yNew = reserve1 + amount;
                if (yNew <= y0) {
                    // remain on g()
                    xNew = CurveLib.f(yNew, py, px, y0, x0, cy);
                } else {
                    // move to f()
                    xNew = CurveLib.fInverse(yNew, px, py, x0, y0, cx);
                }
                output = reserve0 > xNew ? reserve0 - xNew : 0;
            }
        } else {
            // exact out
            if (asset0IsInput) {
                // swap Y out and X in
                if (reserve1 <= amount) return type(uint256).max;
                yNew = reserve1 - amount;
                if (yNew <= y0) {
                    // remain on g()
                    xNew = CurveLib.f(yNew, py, px, y0, x0, cy);
                } else {
                    // move to f()
                    xNew = CurveLib.fInverse(yNew, px, py, x0, y0, cx);
                }
                output = xNew > reserve0 ? xNew - reserve0 : 0;
            } else {
                // swap X out and Y in
                if (reserve0 <= amount) return type(uint256).max;
                xNew = reserve0 - amount;
                if (xNew <= x0) {
                    // remain on f()
                    yNew = CurveLib.f(xNew, px, py, x0, y0, cx);
                } else {
                    // move to g()
                    yNew = CurveLib.fInverse(xNew, py, px, y0, x0, cy);
                }
                output = yNew > reserve1 ? yNew - reserve1 : 0;
            }
        }
    }
}
// SPDX--License-Identifier: MIT
/* pragma solidity >=0.8.0; */

interface IEulerSwapProtocolFeeConfig {
    /// @notice Change the admin
    /// @param newAdmin New admin address (can be address(0) to renounce)
    function setAdmin(address newAdmin) external;

    /// @notice Update the default protocol fee settings
    /// @param recipient Address to receive the protocol fees
    /// @param fee Proportion of LP fees claimed as protocol fees (1e18 scale). Must be <= 15%.
    function setDefault(address recipient, uint64 fee) external;

    /// @notice Override a particular pool's protocol fee settings
    /// @param pool The EulerSwap instance to override
    /// @param recipient Address to receive the protocol fees. If address(0), then use the default recipient.
    /// @param fee Proportion of LP fees claimed as protocol fees (1e18 scale). Must be <= 15%.
    function setOverride(address pool, address recipient, uint64 fee) external;

    /// @notice Removes an override for a particular pool
    /// @param pool The EulerSwap instance
    function removeOverride(address pool) external;

    /// @notice Retrieve protocol fee configuration for a given pool
    /// @param pool Which pool to read the config for
    /// @return recipient Address to receive the protocol fees
    /// @return fee Proportion of LP fees claimed as protocol fees (1e18 scale)
    function getProtocolFee(address pool) external view returns (address recipient, uint64 fee);
}
// SPDX--License-Identifier: BUSL-1.1
/* pragma solidity ^0.8.27; */
/* import {IEulerSwapProtocolFeeConfig} from "./interfaces/IEulerSwapProtocolFeeConfig.sol"; */
/* import {EVCUtil} from "evc/utils/EVCUtil.sol"; */

/// @title EulerSwapProtocolFeeConfig contract
/// @custom:security-contact security@euler.xyz
/// @author Euler Labs (https://www.eulerlabs.com/)
contract EulerSwapProtocolFeeConfig is IEulerSwapProtocolFeeConfig, EVCUtil {
    /// @dev Protocol fee admin
    address public admin;

    /// @dev Admin is not allowed to set a protocol fee larger than this
    uint64 public constant MAX_PROTOCOL_FEE = 0.15e18;

    /// @dev Destination of collected protocol fees, unless overridden
    address public defaultRecipient;
    /// @dev Default protocol fee, 1e18-scale
    uint64 public defaultFee;

    struct Override {
        bool exists;
        address recipient;
        uint64 fee;
    }

    /// @dev EulerSwap-instance specific fee override
    mapping(address pool => Override) public overrides;

    error Unauthorized();
    error InvalidAdminAddress();
    error InvalidProtocolFee();
    error InvalidProtocolFeeRecipient();

    /// @notice Emitted when admin is set/changed
    event AdminUpdated(address indexed oldAdmin, address indexed newAdmin);
    /// @notice Emitted when the default configuration is changed
    event DefaultUpdated(address indexed oldRecipient, address indexed newRecipient, uint64 oldFee, uint64 newFee);
    /// @notice Emitted when a per-pool override is created or changed
    event OverrideSet(address indexed pool, address indexed recipient, uint64 fee);
    /// @notice Emitted when a per-pool override is removed (and thus falls back to the default)
    event OverrideRemoved(address indexed pool);

    constructor(address evc, address admin_) EVCUtil(evc) {
        _validateAdminAddress(admin_);

        emit AdminUpdated(address(0), admin_);

        admin = admin_;
    }

    modifier onlyAdmin() {
        // Ensures that the caller is not an operator, controller, etc
        _authenticateCallerWithStandardContextState(true);

        require(_msgSender() == admin, Unauthorized());

        _;
    }

    /// @inheritdoc IEulerSwapProtocolFeeConfig
    function setAdmin(address newAdmin) external onlyAdmin {
        _validateAdminAddress(newAdmin);

        emit AdminUpdated(admin, newAdmin);

        admin = newAdmin;
    }

    /// @inheritdoc IEulerSwapProtocolFeeConfig
    function setDefault(address recipient, uint64 fee) external onlyAdmin {
        require(fee <= MAX_PROTOCOL_FEE, InvalidProtocolFee());
        require(fee == 0 || recipient != address(0), InvalidProtocolFeeRecipient());

        emit DefaultUpdated(defaultRecipient, recipient, defaultFee, fee);

        defaultRecipient = recipient;
        defaultFee = fee;
    }

    /// @inheritdoc IEulerSwapProtocolFeeConfig
    function setOverride(address pool, address recipient, uint64 fee) external onlyAdmin {
        require(fee <= MAX_PROTOCOL_FEE, InvalidProtocolFee());

        emit OverrideSet(pool, recipient, fee);

        overrides[pool] = Override({exists: true, recipient: recipient, fee: fee});
    }

    /// @inheritdoc IEulerSwapProtocolFeeConfig
    function removeOverride(address pool) external onlyAdmin {
        emit OverrideRemoved(pool);

        delete overrides[pool];
    }

    /// @inheritdoc IEulerSwapProtocolFeeConfig
    function getProtocolFee(address pool) external view returns (address recipient, uint64 fee) {
        Override memory o = overrides[pool];

        if (o.exists) {
            recipient = o.recipient;
            fee = o.fee;

            if (recipient == address(0)) recipient = defaultRecipient;
        } else {
            recipient = defaultRecipient;
            fee = defaultFee;
        }
    }

    /// @dev Ensures the admin is not a known sub-account, since they are not allowed
    function _validateAdminAddress(address addr) internal view {
        address owner = evc.getAccountOwner(addr);
        require(owner == addr || owner == address(0), InvalidAdminAddress());
    }
}
// SPDX--License-Identifier: MIT
/* pragma solidity ^0.8.0; */

interface IEIP712 {
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
// SPDX--License-Identifier: MIT
/* pragma solidity ^0.8.0; */
/* import {IEIP712} from "./IEIP712.sol"; */

/// @title AllowanceTransfer
/// @notice Handles ERC20 token permissions through signature based allowance setting and ERC20 token transfers by checking allowed amounts
/// @dev Requires user's token approval on the Permit2 contract
interface IAllowanceTransfer is IEIP712 {
    /// @notice Thrown when an allowance on a token has expired.
    /// @param deadline The timestamp at which the allowed amount is no longer valid
    error AllowanceExpired(uint256 deadline);

    /// @notice Thrown when an allowance on a token has been depleted.
    /// @param amount The maximum amount allowed
    error InsufficientAllowance(uint256 amount);

    /// @notice Thrown when too many nonces are invalidated.
    error ExcessiveInvalidation();

    /// @notice Emits an event when the owner successfully invalidates an ordered nonce.
    event NonceInvalidation(
        address indexed owner, address indexed token, address indexed spender, uint48 newNonce, uint48 oldNonce
    );

    /// @notice Emits an event when the owner successfully sets permissions on a token for the spender.
    event Approval(
        address indexed owner, address indexed token, address indexed spender, uint160 amount, uint48 expiration
    );

    /// @notice Emits an event when the owner successfully sets permissions using a permit signature on a token for the spender.
    event Permit(
        address indexed owner,
        address indexed token,
        address indexed spender,
        uint160 amount,
        uint48 expiration,
        uint48 nonce
    );

    /// @notice Emits an event when the owner sets the allowance back to 0 with the lockdown function.
    event Lockdown(address indexed owner, address token, address spender);

    /// @notice The permit data for a token
    struct PermitDetails {
        // ERC20 token address
        address token;
        // the maximum amount allowed to spend
        uint160 amount;
        // timestamp at which a spender's token allowances become invalid
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice The permit message signed for a single token allowance
    struct PermitSingle {
        // the permit data for a single token alownce
        PermitDetails details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }

    /// @notice The permit message signed for multiple token allowances
    struct PermitBatch {
        // the permit data for multiple token allowances
        PermitDetails[] details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }

    /// @notice The saved permissions
    /// @dev This info is saved per owner, per token, per spender and all signed over in the permit message
    /// @dev Setting amount to type(uint160).max sets an unlimited approval
    struct PackedAllowance {
        // amount allowed
        uint160 amount;
        // permission expiry
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice A token spender pair.
    struct TokenSpenderPair {
        // the token the spender is approved
        address token;
        // the spender address
        address spender;
    }

    /// @notice Details for a token transfer.
    struct AllowanceTransferDetails {
        // the owner of the token
        address from;
        // the recipient of the token
        address to;
        // the amount of the token
        uint160 amount;
        // the token to be transferred
        address token;
    }

    /// @notice A mapping from owner address to token address to spender address to PackedAllowance struct, which contains details and conditions of the approval.
    /// @notice The mapping is indexed in the above order see: allowance[ownerAddress][tokenAddress][spenderAddress]
    /// @dev The packed slot holds the allowed amount, expiration at which the allowed amount is no longer valid, and current nonce thats updated on any signature based approvals.
    function allowance(address user, address token, address spender)
        external
        view
        returns (uint160 amount, uint48 expiration, uint48 nonce);

    /// @notice Approves the spender to use up to amount of the specified token up until the expiration
    /// @param token The token to approve
    /// @param spender The spender address to approve
    /// @param amount The approved amount of the token
    /// @param expiration The timestamp at which the approval is no longer valid
    /// @dev The packed allowance also holds a nonce, which will stay unchanged in approve
    /// @dev Setting amount to type(uint160).max sets an unlimited approval
    function approve(address token, address spender, uint160 amount, uint48 expiration) external;

    /// @notice Permit a spender to a given amount of the owners token via the owner's EIP-712 signature
    /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
    /// @param owner The owner of the tokens being approved
    /// @param permitSingle Data signed over by the owner specifying the terms of approval
    /// @param signature The owner's signature over the permit data
    function permit(address owner, PermitSingle memory permitSingle, bytes calldata signature) external;

    /// @notice Permit a spender to the signed amounts of the owners tokens via the owner's EIP-712 signature
    /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
    /// @param owner The owner of the tokens being approved
    /// @param permitBatch Data signed over by the owner specifying the terms of approval
    /// @param signature The owner's signature over the permit data
    function permit(address owner, PermitBatch memory permitBatch, bytes calldata signature) external;

    /// @notice Transfer approved tokens from one address to another
    /// @param from The address to transfer from
    /// @param to The address of the recipient
    /// @param amount The amount of the token to transfer
    /// @param token The token address to transfer
    /// @dev Requires the from address to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(address from, address to, uint160 amount, address token) external;

    /// @notice Transfer approved tokens in a batch
    /// @param transferDetails Array of owners, recipients, amounts, and tokens for the transfers
    /// @dev Requires the from addresses to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(AllowanceTransferDetails[] calldata transferDetails) external;

    /// @notice Enables performing a "lockdown" of the sender's Permit2 identity
    /// by batch revoking approvals
    /// @param approvals Array of approvals to revoke.
    function lockdown(TokenSpenderPair[] calldata approvals) external;

    /// @notice Invalidate nonces for a given (token, spender) pair
    /// @param token The token to invalidate nonces for
    /// @param spender The spender to invalidate nonces for
    /// @param newNonce The new nonce to set. Invalidates all nonces less than it.
    /// @dev Can't invalidate more than 2**16 nonces per transaction.
    function invalidateNonces(address token, address spender, uint48 newNonce) external;
}
// SPDX--License-Identifier: BUSL-1.1
/* pragma solidity ^0.8.27; */
/* import {SafeERC20, IERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol"; */
/* import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol"; */
/* import {IEVC} from "evc/interfaces/IEthereumVaultConnector.sol"; */
/* import {IEVault, IBorrowing, IERC4626, IRiskManager} from "evk/EVault/IEVault.sol"; */

library FundsLib {
    using SafeERC20 for IERC20;

    error DepositFailure(bytes reason);

    error E_ZeroShares(); // EVK error
    error ZeroShares(); // Euler Earn error

    /// @notice Approves tokens for a given vault, supporting both standard approvals and permit2
    /// @param vault The address of the vault to approve the token for
    function approveVault(address vault) internal {
        address asset = IEVault(vault).asset();
        address permit2 = IEVault(vault).permit2Address();
        if (permit2 == address(0)) {
            IERC20(asset).forceApprove(vault, type(uint256).max);
        } else {
            IERC20(asset).forceApprove(permit2, type(uint256).max);
            IAllowanceTransfer(permit2).approve(asset, vault, type(uint160).max, type(uint48).max);
        }
    }

    /// @notice Withdraws assets from a vault, first using available balance and then borrowing if needed
    /// @param evc EVC instance
    /// @param eulerAccount Euler account to withdraw/borrow on behalf of
    /// @param supplyVault The address of the vault to withdraw from
    /// @param borrowVault The address of the vault to borrow from
    /// @param amount The total amount of assets to withdraw
    /// @param to The address that will receive the withdrawn assets
    /// @dev This function first checks if there's an existing balance in the vault.
    /// @dev If there is, it withdraws the minimum of the requested amount and available balance.
    /// @dev If more assets are needed after withdrawal, it enables the controller and borrows the remaining amount.
    function withdrawAssets(
        address evc,
        address eulerAccount,
        address supplyVault,
        address borrowVault,
        uint256 amount,
        address to
    ) internal {
        uint256 balance;
        {
            uint256 shares = IEVault(supplyVault).balanceOf(eulerAccount);
            balance = shares == 0 ? 0 : IEVault(supplyVault).convertToAssets(shares);
        }

        if (balance > 0) {
            uint256 avail = amount < balance ? amount : balance;
            IEVC(evc).call(supplyVault, eulerAccount, 0, abi.encodeCall(IERC4626.withdraw, (avail, to, eulerAccount)));
            amount -= avail;
        }

        if (amount > 0) {
            IEVC(evc).enableController(eulerAccount, borrowVault);
            IEVC(evc).call(borrowVault, eulerAccount, 0, abi.encodeCall(IBorrowing.borrow, (amount, to)));
        }
    }

    /// @notice Deposits assets into a vault and automatically repays any outstanding debt
    /// @param evc EVC instance
    /// @param eulerAccount Euler account to repay/deposit on behalf of
    /// @param supplyVault The address of the vault to deposit to
    /// @param borrowVault The address of the vault to repay to
    /// @param amount The total amount to deposit
    /// @return The amount of assets successfully deposited (may be less than requested)
    /// @dev This function attempts to deposit assets into the specified vault.
    /// @dev If the deposit fails with E_ZeroShares or ZeroShares error, it safely returns 0 (this happens with very small amounts).
    /// @dev After successful deposit, if the user has any outstanding controller-enabled debt, it attempts to repay it.
    /// @dev If all debt is repaid, the controller is automatically disabled to reduce gas costs in future operations.
    function depositAssets(address evc, address eulerAccount, address supplyVault, address borrowVault, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 deposited;

        if (IEVC(evc).isControllerEnabled(eulerAccount, borrowVault)) {
            uint256 debt = IEVault(borrowVault).debtOf(eulerAccount);
            uint256 repaid = IEVault(borrowVault).repay(amount > debt ? debt : amount, eulerAccount);

            amount -= repaid;
            debt -= repaid;
            deposited += repaid;

            if (debt == 0) {
                IEVC(evc).call(borrowVault, eulerAccount, 0, abi.encodeCall(IRiskManager.disableController, ()));
            }
        }

        if (amount > 0) {
            try IEVault(supplyVault).deposit(amount, eulerAccount) {}
            catch (bytes memory reason) {
                require(
                    bytes4(reason) == E_ZeroShares.selector || bytes4(reason) == ZeroShares.selector,
                    DepositFailure(reason)
                );
                amount = 0;
            }

            deposited += amount;
        }

        return deposited;
    }
}
// SPDX--License-Identifier: BUSL-1.1
/* pragma solidity ^0.8.27; */
/* import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol"; */
/* import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol"; */
/* import {PoolKey} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol"; */
/* import {Currency} from "@uniswap/v4-core/src/types/Currency.sol"; */
/* import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol"; */
/* import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol"; */
/* import {SafeCast} from "@uniswap/v4-core/src/libraries/SafeCast.sol"; */
/* import {
    BeforeSwapDelta, toBeforeSwapDelta, BeforeSwapDeltaLibrary
} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol"; */
/* import {IEVault} from "evk/EVault/IEVault.sol"; */
/* import {EulerSwapBase} from "./EulerSwapBase.sol"; */
/* import {IEulerSwap} from "./interfaces/IEulerSwap.sol"; */
/* import {QuoteLib} from "./libraries/QuoteLib.sol"; */
/* import {SwapLib} from "./libraries/SwapLib.sol"; */

abstract contract UniswapHook is EulerSwapBase, BaseHook {
    using SafeCast for uint256;

    address public immutable protocolFeeConfig;

    PoolKey internal _poolKey;

    constructor(address evc_, address protocolFeeConfig_, address _poolManager)
        EulerSwapBase(evc_)
        BaseHook(IPoolManager(_poolManager))
    {
        protocolFeeConfig = protocolFeeConfig_;
    }

    function activateHook(IEulerSwap.StaticParams memory sParams) internal nonReentrant {
        if (address(poolManager) == address(0)) return;

        Hooks.validateHookPermissions(this, getHookPermissions());

        address asset0Addr = IEVault(sParams.supplyVault0).asset();
        address asset1Addr = IEVault(sParams.supplyVault1).asset();

        _poolKey = PoolKey({
            currency0: Currency.wrap(asset0Addr),
            currency1: Currency.wrap(asset1Addr),
            fee: 0, // hard-coded fee since it may change
            tickSpacing: 1, // hard-coded tick spacing, as it's unused
            hooks: IHooks(address(this))
        });

        // create the pool on v4, using starting price as sqrtPrice(1/1) * Q96
        poolManager.initialize(_poolKey, 79228162514264337593543950336);
    }

    /// @dev Helper function to return the poolKey as its struct type
    function poolKey() external view returns (PoolKey memory) {
        return _poolKey;
    }

    /// @dev Prevent hook address validation in constructor, which is not needed
    /// because hook instances are proxies. Instead, the address is validated
    /// in activateHook().
    function validateHookAddress(BaseHook _this) internal pure override {}

    function _beforeSwap(address sender, PoolKey calldata key, IPoolManager.SwapParams calldata params, bytes calldata)
        internal
        override
        nonReentrant
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        SwapLib.SwapContext memory ctx = SwapLib.init(address(evc), protocolFeeConfig, sender, msg.sender);

        uint256 amountIn;
        uint256 amountOut;
        BeforeSwapDelta returnDelta;
        bool isExactInput = params.amountSpecified < 0;

        if (isExactInput) {
            amountIn = uint256(-params.amountSpecified);
            amountOut = QuoteLib.computeQuote(address(evc), ctx.sParams, ctx.dParams, params.zeroForOne, amountIn, true);
        } else {
            amountOut = uint256(params.amountSpecified);
            amountIn =
                QuoteLib.computeQuote(address(evc), ctx.sParams, ctx.dParams, params.zeroForOne, amountOut, false);
        }

        if (params.zeroForOne) {
            SwapLib.setAmountsOut(ctx, 0, amountOut);
            SwapLib.setAmountsIn(ctx, amountIn, 0);
        } else {
            SwapLib.setAmountsOut(ctx, amountOut, 0);
            SwapLib.setAmountsIn(ctx, 0, amountIn);
        }

        SwapLib.invokeBeforeSwapHook(ctx);

        // return the delta to the PoolManager, so it can process the accounting
        // exact input:
        //   specifiedDelta = positive, to offset the input token taken by the hook (negative delta)
        //   unspecifiedDelta = negative, to offset the credit of the output token paid by the hook (positive delta)
        // exact output:
        //   specifiedDelta = negative, to offset the output token paid by the hook (positive delta)
        //   unspecifiedDelta = positive, to offset the input token taken by the hook (negative delta)
        returnDelta = isExactInput
            ? toBeforeSwapDelta(amountIn.toInt128(), -(amountOut.toInt128()))
            : toBeforeSwapDelta(-(amountOut.toInt128()), amountIn.toInt128());

        // take the input token, from the PoolManager to the Euler vault
        // the debt will be paid by the swapper via the swap router
        poolManager.take(params.zeroForOne ? key.currency0 : key.currency1, address(this), amountIn);
        SwapLib.doDeposits(ctx);

        // pay the output token, to the PoolManager from an Euler vault
        // the credit will be forwarded to the swap router, which then forwards it to the swapper
        poolManager.sync(params.zeroForOne ? key.currency1 : key.currency0);
        SwapLib.doWithdraws(ctx);
        poolManager.settle();

        SwapLib.finish(ctx);

        return (BaseHook.beforeSwap.selector, returnDelta, 0);
    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        /**
         * @dev Hook Permissions without overrides:
         * - beforeInitialize, beforeDoate, beforeAddLiquidity
         * We use BaseHook's original reverts to *intentionally* revert
         *
         * beforeInitialize: the hook reverts for initializations NOT going through EulerSwap.activateHook()
         * we want to prevent users from initializing other pairs with the same hook address
         *
         * beforeDonate: because the hook does not support native concentrated liquidity, any
         * donations are permanently irrecoverable. The hook reverts on beforeDonate to prevent accidental misusage
         *
         * beforeAddLiquidity: the hook reverts to prevent v3-CLAMM positions
         * because the hook is a "custom curve", any concentrated liquidity position sits idle and entirely unused
         * to protect users from accidentally creating non-productive positions, the hook reverts on beforeAddLiquidity
         */
        return Hooks.Permissions({
            beforeInitialize: true,
            afterInitialize: false,
            beforeAddLiquidity: true,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: false,
            beforeDonate: true,
            afterDonate: false,
            beforeSwapReturnDelta: true,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }
}
// SPDX--License-Identifier: MIT
/* pragma solidity >=0.8.0; */

interface IEulerSwapCallee {
    /// @notice If non-empty data is provided to `swap()`, then this callback function
    /// is invoked on the `to` address, allowing flash-swaps (withdrawing output before
    /// sending input.
    /// @dev This callback mechanism is designed to be as similar as possible to Uniswap2.
    /// @param sender The address that originated the swap
    /// @param amount0 The requested output amount of token0
    /// @param amount1 The requested output amount of token1
    /// @param data Opaque callback data passed by swapper
    function eulerSwapCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external;
}
// SPDX--License-Identifier: BUSL-1.1
/* pragma solidity ^0.8.27; */
/* import {IERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol"; */
/* import {IEulerSwapCallee} from "./interfaces/IEulerSwapCallee.sol"; */
/* import {IEVault} from "evk/EVault/IEVault.sol"; */
/* import {IEulerSwap} from "./interfaces/IEulerSwap.sol"; */
/* import {UniswapHook} from "./UniswapHook.sol"; */
/* import {CtxLib} from "./libraries/CtxLib.sol"; */
/* import {QuoteLib} from "./libraries/QuoteLib.sol"; */
/* import {SwapLib} from "./libraries/SwapLib.sol"; */

contract EulerSwap is IEulerSwap, UniswapHook {
    bytes32 public constant curve = bytes32("EulerSwap v2");
    address public immutable managementImpl;

    error AmountTooBig();

    constructor(address evc_, address protocolFeeConfig_, address poolManager_, address managementImpl_)
        UniswapHook(evc_, protocolFeeConfig_, poolManager_)
    {
        managementImpl = managementImpl_;
    }

    /// @inheritdoc IEulerSwap
    function activate(DynamicParams calldata, InitialState calldata) external {
        _delegateToManagementImpl();

        // Uniswap hook activation

        activateHook(CtxLib.getStaticParams());
    }

    /// @inheritdoc IEulerSwap
    function setManager(address, bool) external {
        _delegateToManagementImpl();
    }

    /// @inheritdoc IEulerSwap
    function reconfigure(DynamicParams calldata, InitialState calldata) external {
        _delegateToManagementImpl();
    }

    /// @inheritdoc IEulerSwap
    function managers(address manager) external view returns (bool installed) {
        CtxLib.State storage s = CtxLib.getState();
        return s.managers[manager];
    }

    /// @inheritdoc IEulerSwap
    function getStaticParams() external pure returns (StaticParams memory) {
        return CtxLib.getStaticParams();
    }

    /// @inheritdoc IEulerSwap
    function getDynamicParams() external pure returns (DynamicParams memory) {
        return CtxLib.getDynamicParams();
    }

    /// @inheritdoc IEulerSwap
    function getAssets() external view returns (address asset0, address asset1) {
        StaticParams memory sParams = CtxLib.getStaticParams();

        asset0 = IEVault(sParams.supplyVault0).asset();
        asset1 = IEVault(sParams.supplyVault1).asset();
    }

    /// @inheritdoc IEulerSwap
    function getReserves() external view nonReentrantView returns (uint112, uint112, uint32) {
        CtxLib.State storage s = CtxLib.getState();

        return (s.reserve0, s.reserve1, s.status);
    }

    /// @inheritdoc IEulerSwap
    function isInstalled() external view nonReentrantView returns (bool) {
        StaticParams memory sParams = CtxLib.getStaticParams();

        return evc.isAccountOperatorAuthorized(sParams.eulerAccount, address(this));
    }

    /// @inheritdoc IEulerSwap
    function computeQuote(address tokenIn, address tokenOut, uint256 amount, bool exactIn)
        external
        view
        nonReentrantView
        returns (uint256)
    {
        StaticParams memory sParams = CtxLib.getStaticParams();
        DynamicParams memory dParams = CtxLib.getDynamicParams();

        return QuoteLib.computeQuote(
            address(evc), sParams, dParams, QuoteLib.checkTokens(sParams, tokenIn, tokenOut), amount, exactIn
        );
    }

    /// @inheritdoc IEulerSwap
    function getLimits(address tokenIn, address tokenOut)
        external
        view
        nonReentrantView
        returns (uint256 inLimit, uint256 outLimit)
    {
        StaticParams memory sParams = CtxLib.getStaticParams();
        DynamicParams memory dParams = CtxLib.getDynamicParams();

        if (!evc.isAccountOperatorAuthorized(sParams.eulerAccount, address(this))) return (0, 0);
        if (dParams.expiration != 0 && dParams.expiration <= block.timestamp) return (0, 0);

        bool asset0IsInput = QuoteLib.checkTokens(sParams, tokenIn, tokenOut);

        uint256 fee = QuoteLib.getFeeReadOnly(dParams, asset0IsInput);
        if (fee >= 1e18) return (0, 0);

        (inLimit, outLimit) = QuoteLib.calcLimits(sParams, dParams, asset0IsInput, fee);
        if (outLimit > 0) outLimit--; // Compensate for rounding up of exact output quotes
    }

    /// @inheritdoc IEulerSwap
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data)
        external
        callThroughEVC
        nonReentrant
    {
        require(amount0Out <= type(uint112).max && amount1Out <= type(uint112).max, AmountTooBig());

        // Setup context

        SwapLib.SwapContext memory ctx = SwapLib.init(address(evc), protocolFeeConfig, _msgSender(), to);
        SwapLib.setAmountsOut(ctx, amount0Out, amount1Out);
        SwapLib.invokeBeforeSwapHook(ctx);

        // Optimistically send tokens

        SwapLib.doWithdraws(ctx);

        // Invoke callback

        if (data.length > 0) IEulerSwapCallee(to).eulerSwapCall(_msgSender(), amount0Out, amount1Out, data);

        // Deposit all available funds

        SwapLib.setAmountsIn(
            ctx, IERC20(ctx.asset0).balanceOf(address(this)), IERC20(ctx.asset1).balanceOf(address(this))
        );
        SwapLib.doDeposits(ctx);

        // Verify curve invariant is satisfied

        SwapLib.finish(ctx);
    }

    function _delegateToManagementImpl() internal {
        (bool success, bytes memory result) = managementImpl.delegatecall(msg.data);
        if (!success) {
            assembly {
                revert(add(32, result), mload(result))
            }
        }
    }
}
// SPDX--License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (utils/Address.sol)

/* pragma solidity ^0.8.20; */
/* import {Errors} from "./Errors.sol"; */

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

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
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert Errors.InsufficientBalance(address(this).balance, amount);
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert Errors.FailedCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {Errors.FailedCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert Errors.InsufficientBalance(address(this).balance, value);
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {Errors.FailedCall}) in case
     * of an unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {Errors.FailedCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {Errors.FailedCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            assembly ("memory-safe") {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert Errors.FailedCall();
        }
    }
}
// SPDX--License-Identifier: MIT
/* pragma solidity ^0.8.0; */

/// @title Minimal ERC20 interface for Uniswap
/// @notice Contains a subset of the full ERC20 interface that is used in Uniswap V3
interface IERC20Minimal {
    /// @notice Returns an account's balance in the token
    /// @param account The account for which to look up the number of tokens it has, i.e. its balance
    /// @return The number of tokens held by the account
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfers the amount of token from the `msg.sender` to the recipient
    /// @param recipient The account that will receive the amount transferred
    /// @param amount The number of tokens to send from the sender to the recipient
    /// @return Returns true for a successful transfer, false for an unsuccessful transfer
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Returns the current allowance given to a spender by an owner
    /// @param owner The account of the token owner
    /// @param spender The account of the token spender
    /// @return The current allowance granted by `owner` to `spender`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets the allowance of a spender from the `msg.sender` to the value `amount`
    /// @param spender The account which will be allowed to spend a given amount of the owners tokens
    /// @param amount The amount of tokens allowed to be used by `spender`
    /// @return Returns true for a successful approval, false for unsuccessful
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfers `amount` tokens from `sender` to `recipient` up to the allowance given to the `msg.sender`
    /// @param sender The account from which the transfer will be initiated
    /// @param recipient The recipient of the transfer
    /// @param amount The amount of the transfer
    /// @return Returns true for a successful transfer, false for unsuccessful
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /// @notice Event emitted when tokens are transferred from one address to another, either via `#transfer` or `#transferFrom`.
    /// @param from The account from which the tokens were sent, i.e. the balance decreased
    /// @param to The account to which the tokens were sent, i.e. the balance increased
    /// @param value The amount of tokens that were transferred
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Event emitted when the approval amount for the spender of a given owner's tokens changes.
    /// @param owner The account that approved spending of its tokens
    /// @param spender The account for which the spending allowance was modified
    /// @param value The new allowance from the owner to the spender
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// SPDX--License-Identifier: MIT
/* pragma solidity ^0.8.0; */
/* import {IERC20Minimal} from "../interfaces/external/IERC20Minimal.sol"; */
/* import {CustomRevert} from "../libraries/CustomRevert.sol"; */

type Currency is address;

using {greaterThan as >, lessThan as <, greaterThanOrEqualTo as >=, equals as ==} for Currency global;
using CurrencyLibrary for Currency global;

function equals(Currency currency, Currency other) pure returns (bool) {
    return Currency.unwrap(currency) == Currency.unwrap(other);
}

function greaterThan(Currency currency, Currency other) pure returns (bool) {
    return Currency.unwrap(currency) > Currency.unwrap(other);
}

function lessThan(Currency currency, Currency other) pure returns (bool) {
    return Currency.unwrap(currency) < Currency.unwrap(other);
}

function greaterThanOrEqualTo(Currency currency, Currency other) pure returns (bool) {
    return Currency.unwrap(currency) >= Currency.unwrap(other);
}

/// @title CurrencyLibrary
/// @dev This library allows for transferring and holding native tokens and ERC20 tokens
library CurrencyLibrary {
    /// @notice Additional context for ERC-7751 wrapped error when a native transfer fails
    error NativeTransferFailed();

    /// @notice Additional context for ERC-7751 wrapped error when an ERC20 transfer fails
    error ERC20TransferFailed();

    /// @notice A constant to represent the native currency
    Currency public constant ADDRESS_ZERO = Currency.wrap(address(0));

    function transfer(Currency currency, address to, uint256 amount) internal {
        // altered from https://github.com/transmissions11/solmate/blob/44a9963d4c78111f77caa0e65d677b8b46d6f2e6/src/utils/SafeTransferLib.sol
        // modified custom error selectors

        bool success;
        if (currency.isAddressZero()) {
            assembly ("memory-safe") {
                // Transfer the ETH and revert if it fails.
                success := call(gas(), to, amount, 0, 0, 0, 0)
            }
            // revert with NativeTransferFailed, containing the bubbled up error as an argument
            if (!success) {
                CustomRevert.bubbleUpAndRevertWith(to, bytes4(0), NativeTransferFailed.selector);
            }
        } else {
            assembly ("memory-safe") {
                // Get a pointer to some free memory.
                let fmp := mload(0x40)

                // Write the abi-encoded calldata into memory, beginning with the function selector.
                mstore(fmp, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
                mstore(add(fmp, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
                mstore(add(fmp, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

                success :=
                    and(
                        // Set success to whether the call reverted, if not we check it either
                        // returned exactly 1 (can't just be non-zero data), or had no return data.
                        or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                        // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                        // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                        // Counterintuitively, this call must be positioned second to the or() call in the
                        // surrounding and() call or else returndatasize() will be zero during the computation.
                        call(gas(), currency, 0, fmp, 68, 0, 32)
                    )

                // Now clean the memory we used
                mstore(fmp, 0) // 4 byte `selector` and 28 bytes of `to` were stored here
                mstore(add(fmp, 0x20), 0) // 4 bytes of `to` and 28 bytes of `amount` were stored here
                mstore(add(fmp, 0x40), 0) // 4 bytes of `amount` were stored here
            }
            // revert with ERC20TransferFailed, containing the bubbled up error as an argument
            if (!success) {
                CustomRevert.bubbleUpAndRevertWith(
                    Currency.unwrap(currency), IERC20Minimal.transfer.selector, ERC20TransferFailed.selector
                );
            }
        }
    }

    function balanceOfSelf(Currency currency) internal view returns (uint256) {
        if (currency.isAddressZero()) {
            return address(this).balance;
        } else {
            return IERC20Minimal(Currency.unwrap(currency)).balanceOf(address(this));
        }
    }

    function balanceOf(Currency currency, address owner) internal view returns (uint256) {
        if (currency.isAddressZero()) {
            return owner.balance;
        } else {
            return IERC20Minimal(Currency.unwrap(currency)).balanceOf(owner);
        }
    }

    function isAddressZero(Currency currency) internal pure returns (bool) {
        return Currency.unwrap(currency) == Currency.unwrap(ADDRESS_ZERO);
    }

    function toId(Currency currency) internal pure returns (uint256) {
        return uint160(Currency.unwrap(currency));
    }

    // If the upper 12 bytes are non-zero, they will be zero-ed out
    // Therefore, fromId() and toId() are not inverses of each other
    function fromId(uint256 id) internal pure returns (Currency) {
        return Currency.wrap(address(uint160(id)));
    }
}
// SPDX--License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC20.sol)

/* pragma solidity ^0.8.20; */
/* import {IERC20} from "../token/ERC20/IERC20.sol"; */
// SPDX--License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC165.sol)

/* pragma solidity ^0.8.20; */
/* import {IERC165} from "../utils/introspection/IERC165.sol"; */
// SPDX--License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (utils/Errors.sol)

/* pragma solidity ^0.8.20; */

/**
 * @dev Collection of common custom errors used in multiple contracts
 *
 * IMPORTANT: Backwards compatibility is not guaranteed in future versions of the library.
 * It is recommended to avoid relying on the error API for critical functionality.
 *
 * _Available since v5.1._
 */
library Errors {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error InsufficientBalance(uint256 balance, uint256 needed);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedCall();

    /**
     * @dev The deployment failed.
     */
    error FailedDeployment();

    /**
     * @dev A necessary precompile is missing.
     */
    error MissingPrecompile(address);
}
// SPDX--License-Identifier: MIT
/* pragma solidity ^0.8.0; */
/* import {PoolKey} from "./PoolKey.sol"; */

type PoolId is bytes32;

/// @notice Library for computing the ID of a pool
library PoolIdLibrary {
    /// @notice Returns value equal to keccak256(abi.encode(poolKey))
    function toId(PoolKey memory poolKey) internal pure returns (PoolId poolId) {
        assembly ("memory-safe") {
            // 0xa0 represents the total size of the poolKey struct (5 slots of 32 bytes)
            poolId := keccak256(poolKey, 0xa0)
        }
    }
}
