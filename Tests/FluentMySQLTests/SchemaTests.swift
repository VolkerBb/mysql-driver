import XCTest
@testable import FluentMySQL
import Fluent

class SchemaTests: XCTestCase {
    static let allTests = [
        ("testBasic", testBasic)
    ]

    var database: Fluent.Database!
    var driver: MySQLDriver!

    override func setUp() {
        driver = MySQLDriver.makeTestConnection()
        database = Database(driver)
    }

    final class SchemaTester: Entity {
        static var entity = "schema_tests"

        var int: Int
        var stringDefault: String
        var string64: String
        var double: Double
        var bool: Bool
        var data: [UInt8]

        let storage = Storage()

        init(
            int: Int,
            stringDefault: String,
            string64: String,
            double: Double,
            bool: Bool,
            data: [UInt8]
        ) {
            self.int = int
            self.stringDefault = stringDefault
            self.string64 = string64
            self.double = double
            self.bool = bool
            self.data = data
        }

        init(node: Node, in context: Context) throws {
            int = try node.get("int")
            stringDefault = try node.get("string_default")
            string64 = try node.get("string_64")
            double = try node.get("double")
            bool = try node.get("bool")
            data = try node.get("data")
        }

        func makeNode(in context: Context) throws -> Node {
            return try Node(node: [
                "id": id,
                "int": int,
                "string_default": stringDefault,
                "string_64": string64,
                "double": double,
                "bool": bool,
                "data": Node(node: data)
            ])
        }

        static func prepare(_ database: Database) throws {
            try database.create(self) { builder in
                builder.id(for: self)
                builder.int("int")
                builder.string("string_default")
                builder.string("string_64", length: 64)
                builder.double("double")
                builder.bool("bool")
                builder.data("data")
            }
        }
        static func revert(_ database: Database) throws {
            try database.delete(self)
        }
    }

    func testBasic() throws {
        SchemaTester.database = database

        try SchemaTester.revert(database)
        try SchemaTester.prepare(database)

        let test = SchemaTester(
            int: 42,
            stringDefault: "this is a default",
            string64: "< 64 bytes",
            double: 3.14,
            bool: false,
            data: [0x04, 0x02]
        )

        do {
            try test.save()
        } catch {
            XCTFail("Could not save: \(error)")
        }
    }
}
