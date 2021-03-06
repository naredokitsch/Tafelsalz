/**
	A master key can be used to derive keys for other purposes.

	## Examples

	```swift
	let context = MasterKey.Context("Examples")!
	let masterKey = MasterKey()
	let subKey1 = masterKey.derive(sizeInBytes: MasterKey.DerivedKey.MinimumSizeInBytes, with: 0, and: context)!
	let subKey2 = masterKey.derive(sizeInBytes: MasterKey.DerivedKey.MinimumSizeInBytes, with: 1, and: context)!

	// You can also derive a key in order to use it with secret boxes
	let secretBox = SecretBox(secretKey: masterKey.derive(with: 0, and: context))
	```
*/
public class MasterKey: KeyMaterial {

	/**
		The size of the master key in bytes.
	*/
	public static let SizeInBytes = UInt32(sodium.kdf.masterKeySizeInBytes)

	/**
		A context for which the derived keys should be used.
	*/
	public struct Context {

		/**
			The size of the context in bytes.
		*/
		public static let SizeInBytes = UInt32(sodium.kdf.contextSizeInBytes)

		/**
			The description of the context in bytes.
		*/
		public let bytes: Bytes

		/**
			Initialize a context from a given byte array.
		
			- parameters:
				- bytes: The byte array.
		*/
		public init?(_ bytes: Bytes) {
			guard UInt32(bytes.count) == Context.SizeInBytes else { return nil }

			self.bytes = bytes
		}

		/**
			Initialize a context from a given string.
		
			- parameters:
				- string: The string.
		*/
		public init?(_ string: String) {
			self.init(string.utf8Bytes)
		}

	}

	/**
		A key that is derived from a `MasterKey`.
	*/
	public class DerivedKey: KeyMaterial {

		/**
			The minimum size of the derived key in bytes.
		*/
		public static let MinimumSizeInBytes = UInt32(sodium.kdf.minimumSubKeySizeInBytes)

		/**
			The maximum size of the derived key in bytes.
		*/
		public static let MaximumSizeInBytes = UInt32(sodium.kdf.maximumSubKeySizeInBytes)

		/**
			Generate an uninitialized key, as the initialization will happen
			during derivation.
		
			- parameters:
				- sizeInBytes: The size of the derived key in bytes.
		*/
		fileprivate init?(sizeInBytes: UInt32) {
			guard DerivedKey.MinimumSizeInBytes <= sizeInBytes else { return nil }
			guard sizeInBytes <= DerivedKey.MaximumSizeInBytes else { return nil }

			super.init(sizeInBytes: sizeInBytes, initialize: false)
		}

	}

	/**
		Initialize a master key.
	*/
	public init() {
		super.init(sizeInBytes: MasterKey.SizeInBytes, initialize: false)

		withUnsafeMutableBytes { sodium.kdf.keygen($0) }
	}

	/**
		Initialize a master key from a given byte array. he byte array is copied
		to a secure location and overwritten with zeroes to avoid the key being
		compromised in memory.
	
		- warning:
			Do not initialize new keys with this function. If you need a new
			key, use `init?()` instead. This initializer is only to restore
			secret keys that were persisted.

		- parameters:
			- bytes: A master key.
	*/
	public override init?(bytes: inout Bytes) {
		guard UInt32(bytes.count) == MasterKey.SizeInBytes else { return nil }

		super.init(bytes: &bytes)
	}

	/**
		Derive a key with a given size for a given id and context.
	
		A derived key will differ if the `id` or the `context` differs.
	
		- parameters:
			- sizeInBytes: The size of the derived key in bytes.
			- id: The ID of the derived key.
			- context: A context in which the derived key is used.
	*/
	public func derive(sizeInBytes: UInt32, with id: UInt64, and context: Context) -> DerivedKey? {
		guard let derivedKey = DerivedKey(sizeInBytes: sizeInBytes) else { return nil }

		withUnsafeBytes {
			masterKeyPtr in

			derivedKey.withUnsafeMutableBytes {
				derivedKeyPtr in

				sodium.kdf.derive(
					subKey: derivedKeyPtr,
					subKeySizeInBytes: Int(sizeInBytes),
					subKeyId: id,
					context: context.bytes,
					masterKey: masterKeyPtr
				)
			}
		}

		return derivedKey
	}

	/**
		Derive a secret key that can be used with `SecretBox`.
	
		- parameters:
			- id: The ID of the derived key.]
			- context: A context in which the derived key is used.
	
		- returns: The secret key.
	*/
	public func derive(with id: UInt64, and context: Context) -> SecretBox.SecretKey {
		let derivedKey = derive(sizeInBytes: SecretBox.SecretKey.SizeInBytes, with: id, and: context)!
		return SecretBox.SecretKey(derivedKey)
	}

	/**
		Derive a key that can be used for personalized hashing.

		- parameters:
			- id: The ID of the derived key.]
			- context: A context in which the derived key is used.
			- outputSizeInBytes: The size of the key in bytes.
	
		- returns: `nil` if the size is not valid.
	*/
	public func derive(with id: UInt64, and context: Context, outputSizeInBytes: UInt32 = GenericHash.DefaultSizeInBytes) -> GenericHash.Key? {
		guard GenericHash.Key.MinimumSizeInBytes <= outputSizeInBytes else { return nil }
		guard outputSizeInBytes <= GenericHash.Key.MaximumSizeInBytes else { return nil }
		let derivedKey = derive(sizeInBytes: sizeInBytes, with: id, and: context)!
		return GenericHash.Key(derivedKey)
	}

}
