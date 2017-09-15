import XCTest

import Tafelsalz

class Examples: XCTestCase {

	func testSymmetricEncryptionWithEphemeralKeys() {
		let secretBox = SecretBox()
		let plaintext = Data("Hello, World!".utf8)
		let ciphertext = secretBox.encrypt(data: plaintext)
		let decrypted = secretBox.decrypt(data: ciphertext)!

		XCTAssertEqual(decrypted, plaintext)
	}

	func testSymmetricEncryptionWithPersistedKeys() {
		// Create a persona
		let alice = Persona(uniqueName: "Alice")

		// Once a secret of that persona is used, it will be persisted in the
		// system's Keychain.
		let secretBox = SecretBox(persona: alice)!

		// Use your SecretBox as usual
		let plaintext = Data("Hello, World!".utf8)
		let ciphertext = secretBox.encrypt(data: plaintext)
		let decrypted = secretBox.decrypt(data: ciphertext)!

		// Forget the persona and remove all related Keychain entries
		try! Persona.forget(alice)

		XCTAssertEqual(decrypted, plaintext)
	}

	func testPasswordHashing() {
		let password = Password("Correct Horse Battery Staple")!
		let hashedPassword = password.hash()!

		// Store `hashedPassword.string` to database.

		// If a user wants to authenticate, just read it from the database and
		// verify it against the password given by the user.
		if hashedPassword.isVerified(by: password) {
			// The user is authenticated successfully.
		}
	}

	func testPublicGenericHashing() {
		let data = Data("Hello, World!".utf8)
		let hash = GenericHash(bytes: data)

		XCTAssertNotNil(hash)
	}

	func testPrivateGenericHashingWithPersistedKeys() {
		// Create a persona
		let alice = Persona(uniqueName: "Alice")

		// Generate a personalized hash for that persona
		let data = Data("Hello, World!".utf8)
		let hash = GenericHash(bytes: data, for: alice)

		// Forget the persona and remove all related Keychain entries
		try! Persona.forget(alice)

		XCTAssertNotNil(hash)
	}

	func testKeyDerivation() {
		let context = MasterKey.Context("Examples")!
		let masterKey = MasterKey()
		let subKey1 = masterKey.derive(sizeInBytes: MasterKey.DerivedKey.MinimumSizeInBytes, with: 0, and: context)!
		let subKey2 = masterKey.derive(sizeInBytes: MasterKey.DerivedKey.MinimumSizeInBytes, with: 1, and: context)!

		// You can also derive a key in order to use it with secret boxes
		let secretBox = SecretBox(secretKey: masterKey.derive(with: 0, and: context))

		KMAssertNotEqual(subKey1, subKey2)
		XCTAssertNotNil(secretBox)
	}
}