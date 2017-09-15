import Keychain

/**
	A persona is an entity for which you are in posession of the secrets. The
	secrets are persisted in the system's Keychain. A persona has a unique name.

	The Keychain items are prefixed by the application's bundle identifier and
	suffixed with a value determining the type of secret stored.

	The actual value of the secret is Base64 encoded to allow users accessing
	the value from the Keychain Access application (macOS)

	- note:
		The persona is unique per device and application bundle identifier. If
		you create two personas with equal names on two different applications
		or devices, they cannot be used to decrypt secrets of one another. If a
		persona is removed and re-created with the same name, it cannot be used
		to decrypt values encrypted for the previous one.
*/
public class Persona {

	/**
		These errors indicate that erroneous keys where stored in the Keychain.
	*/
	enum Error: Swift.Error {
		/**
			This indicates that the key is not Base64-encoded.
		*/
		case failedToDecodeKey

		/**
			This indicates that a key has an invalid size.
		*/
		case invalidKey
	}

	/**
		Forget a persona. This will remove all secrets of this persona from the
		system's Keychain.

		- warning: Removing a persona will delete all secrets of that persona
			which also means, that encrypted messages or files encrypted for
			this persona cannot be decrypted anymore.

		- parameters:
			- persona: The persona that should be deleted.
	*/
	public static func forget(_ persona: Persona) throws {
		for item in persona.keychainItems {
			do {
				try Keychain.delete(item: item)
			} catch Keychain.Error.itemNotFound {
				// Ignore non-existing items
			}
		}
	}

	/**
		The unique name of the persona.
	*/
	public let uniqueName: String

	/**
		Create a new persona. If the persona was created before, the secrets
		will be retrieved from the system's Keychain.

		- parameters:
			- uniqueName: A name that is unique for that persona.
	*/
	public init(uniqueName: String) {
		self.uniqueName = uniqueName
	}

	/**
		Helper function to store key material in the system's Keychain for this
		persona.

		- parameters:
			- item: The item that identifies a Keychain entry.
			- defaultInitializer: A default initializer used for new keys.
			- capturingInitializer: An initializer that takes a byte array.

		- returns:
			The key for the item. A new key, if the item did not exist, the
			existing key else and `nil` if there was an error.
	*/
	private func secret<Key: KeyMaterial>(for type: KeyType, defaultInitializer: () -> Key, capturingInitializer: (inout Data) -> Key?) throws -> Key {
		let item = keychainItem(for: type)
		do {
			// Try to read the key from the Keychain
			let encodedKey: Data = try Keychain.retrievePassword(for: item)

			guard var keyBytes = Data(base64Encoded: encodedKey) else {
				throw Error.failedToDecodeKey
			}

			guard let key = capturingInitializer(&keyBytes) else {
				throw Error.invalidKey
			}

			return key
		} catch Keychain.Error.itemNotFound {
			// If there is no key stored in the Keychain, create a new one and
			// add it to the Keychain.
			let key = defaultInitializer()

			try Keychain.store(password: key.copyBytes().base64EncodedData(), in: item)
			return key
		}
	}

	/**
		The master key of the persona, which can be used to derive other keys.
	
		- returns:
			The master key.
	*/
	public func masterKey() throws -> MasterKey {
		return try secret(for: .masterKey, defaultInitializer: { MasterKey() }, capturingInitializer: { MasterKey(bytes: &$0) })
	}

	/**
		The secret key of the persona that can be used with `SecretBox`.

		- returns: The secret key.
	*/
	public func secretKey() throws -> SecretBox.SecretKey {
		return try secret(for: .secretKey, defaultInitializer: { SecretBox.SecretKey() }, capturingInitializer: { SecretBox.SecretKey(bytes: &$0) })
	}

	/**
		The key of the persona that can be used with `GenericHash`.

		- returns: The key.
	*/
	public func genericHashKey() throws -> GenericHash.Key {
		return try secret(for: .genericHashKey, defaultInitializer: { GenericHash.Key() }, capturingInitializer: { GenericHash.Key(bytes: &$0) })
	}

	/**
		This is used to identify the type of the key.
	*/
	public enum KeyType: String {
		/**
			This identifies keys that cen be used for deriving other keys.
		*/
		case masterKey = "MasterKey"

		/**
			This identifies secret keys that can be used with the secret box.
		*/
		case secretKey = "SecretBox.SecretKey"

		/**
			This identifies keys that can be used for generic hashing.
		*/
		case genericHashKey = "GenericHash.Key"
	}

	/**
		This is the bundle identifier of the application. It is used to identify
		the service of the password item in the system's Keychain.
	*/
	private var bundleIdentifier: String {
		guard Bundle.main.bundleIdentifier == nil else {
			return Bundle.main.bundleIdentifier!
		}

		for bundle in Bundle.allBundles {
			guard bundle.bundleIdentifier == nil else {
				return bundle.bundleIdentifier!
			}
		}

		return ""
	}

	/**
		This constructs an identifier for the service and type of key.

		- parameters:
			- type: The type of the key.

		- returns: The identifier.
	*/
	private func itemService(type: KeyType) -> String {
		return bundleIdentifier + "/" + type.rawValue
	}

	/**
		This identifies the Keychain entry for the given key type.
	*/
	public func keychainItem(for type: KeyType) -> GenericPasswordItem {
		return GenericPasswordItem(for: itemService(type: type), using: uniqueName)
	}

	/**
		This is an array that holds all Keychain entries for this persona.
	*/
	private var keychainItems: [KeychainItem] {
		get {
			return [keychainItem(for: .masterKey), keychainItem(for: .secretKey), keychainItem(for: .genericHashKey)]
		}
	}
}