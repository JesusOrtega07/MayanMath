//
//  MayanMathCoreTests.swift
//  MayanMathTests
//
//  Pruebas del back de la calculadora (Swift Testing).
//

import Testing
@testable import MayanMath

// MARK: - Dígito

struct MayanDigitTests {
    @Test func composicionConBarrasYPuntos() throws {
        let trece = try #require(MayanDigit(13))
        #expect(trece.bars == 2)
        #expect(trece.dots == 3)
        #expect(trece.symbols == [.dot, .dot, .dot, .bar, .bar])
    }

    @Test func ceroEsConcha() {
        #expect(MayanDigit.zero.symbols == [.shell])
    }

    @Test(arguments: [-1, 20, 100])
    func rechazaValoresFueraDeNivel(_ value: Int) {
        #expect(MayanDigit(value) == nil)
    }

    @Test func paletaComoEnLasVistas() {
        #expect(MayanDigit.palette.map(\.value) == [1, 2, 3, 4, 5, 6, 7, 8, 9, 0])
    }
}

// MARK: - Número

struct MayanNumberTests {
    @Test func veintitres() {
        // 1 veintena + 3 unidades → un punto arriba, tres puntos abajo.
        #expect(MayanNumber(23).digits.map(\.value) == [3, 1])
    }

    @Test func trescientosQuince() {
        let n = MayanNumber(315)
        #expect(n.digits.map(\.value) == [15, 15])
        #expect(n.vigesimalNotation == "15.15")
        #expect(n.breakdown.map(\.contribution) == [300, 15])
    }

    @Test func ceroIntermedio() {
        #expect(MayanNumber(400).digits.map(\.value) == [0, 0, 1])
    }

    @Test(arguments: [0, 1, 19, 20, 399, 400, 7_999, 3_199_999])
    func idaYVuelta(_ value: Int) {
        let n = MayanNumber(value)
        #expect(n.value == value)
        #expect(MayanNumber(digits: n.digits) == n)
    }

    @Test func limites() {
        #expect(MayanLimits.maxInputValue == 399)
        #expect(MayanLimits.maxResultValue == 3_199_999)
    }

    @Test func quitaCerosSobrantesArriba() {
        let n = MayanNumber(digits: [MayanDigit(5)!, .zero, .zero])
        #expect(n.levelCount == 1)
        #expect(n.value == 5)
    }
}

// MARK: - Constructor (fichas que se suman)

struct MayanNumberBuilderTests {
    @Test func fichasSeSumanEnUnNivel() throws {
        var b = MayanNumberBuilder()
        try b.add(MayanDigit(5)!, toLevel: 0)
        try b.add(MayanDigit(5)!, toLevel: 0)
        try b.add(MayanDigit(3)!, toLevel: 0)
        #expect(b.value == 13)
    }

    @Test func cincoPuntosFormanBarra() throws {
        var b = MayanNumberBuilder()
        try b.add(MayanDigit(3)!, toLevel: 0)
        let events = try b.add(MayanDigit(4)!, toLevel: 0)
        #expect(events == [.dotsBecameBar(level: 0, count: 1)])
        #expect(b.value == 7)
    }

    @Test func veinteSubeAlNivelSuperior() throws {
        var b = MayanNumberBuilder()
        try b.add(MayanDigit(9)!, toLevel: 0)
        try b.add(MayanDigit(9)!, toLevel: 0)
        let events = try b.add(MayanDigit(5)!, toLevel: 0) // 23
        #expect(events.contains(.carried(fromLevel: 0, toLevel: 1, dots: 1)))
        #expect(b.levels[0] == 3)
        #expect(b.levels[1] == 1)
        #expect(b.value == 23)
    }

    @Test func desbordamientoNoCambiaNada() throws {
        var b = MayanNumberBuilder(maxLevels: 1)
        try b.add(MayanDigit(9)!, toLevel: 0)
        try b.add(MayanDigit(9)!, toLevel: 0)
        #expect(throws: BuilderError.overflow(maxValue: 19)) {
            try b.add(MayanDigit(5)!, toLevel: 0)
        }
        #expect(b.value == 18)
    }

    @Test func conchaMarcaCeroYHuecosSeVenComoConcha() throws {
        var b = MayanNumberBuilder(maxLevels: 3)
        try b.add(MayanDigit(1)!, toLevel: 2) // 400
        #expect(b.content(atLevel: 1) == .digit(.zero))
        #expect(b.content(atLevel: 0) == .digit(.zero))
        #expect(b.value == 400)

        var c = MayanNumberBuilder()
        try c.add(.zero, toLevel: 0)
        #expect(!c.isEmpty)
        #expect(c.value == 0)
    }

    @Test func quitarSimbolos() throws {
        var b = MayanNumberBuilder()
        try b.add(MayanDigit(7)!, toLevel: 0)
        try b.remove(.bar, fromLevel: 0)
        #expect(b.value == 2)
        try b.remove(.dot, fromLevel: 0)
        #expect(b.value == 1)
        #expect(throws: BuilderError.nothingToRemove) {
            try b.remove(.bar, fromLevel: 0)
        }
    }

    @Test func calculadoraSoloDosNiveles() {
        var b = MayanNumberBuilder()
        #expect(b.maxLevels == 2)
        #expect(throws: BuilderError.levelOutOfRange(2)) {
            try b.add(MayanDigit(1)!, toLevel: 2)
        }
    }

    @Test func nivelInexistente() {
        var b = MayanNumberBuilder()
        #expect(throws: BuilderError.levelOutOfRange(5)) {
            try b.add(MayanDigit(1)!, toLevel: 5)
        }
    }
}

// MARK: - Operaciones

struct MayanCalculatorTests {
    @Test func sumaDeLaVista() throws {
        let r = try MayanCalculator.calculate(MayanNumber(248), .addition, MayanNumber(67))
        #expect(r.value.value == 315)
    }

    @Test func restaNegativa() {
        #expect(throws: CalculationError.negativeResult) {
            try MayanCalculator.calculate(MayanNumber(5), .subtraction, MayanNumber(7))
        }
    }

    @Test func multiplicacion() throws {
        let r = try MayanCalculator.calculate(MayanNumber(20), .multiplication, MayanNumber(20))
        #expect(r.value.digits.map(\.value) == [0, 0, 1])
    }

    @Test func divisionConResiduo() throws {
        let r = try MayanCalculator.calculate(MayanNumber(17), .division, MayanNumber(5))
        #expect(r.value.value == 3)
        #expect(r.remainder?.value == 2)
        #expect(r.hasRemainder)
    }

    @Test func divisionEntreCero() {
        #expect(throws: CalculationError.divisionByZero) {
            try MayanCalculator.calculate(MayanNumber(7), .division, .zero)
        }
    }

    @Test func resultadoDemasiadoGrande() {
        #expect(throws: CalculationError.overflow(maxValue: MayanLimits.maxResultValue)) {
            try MayanCalculator.calculate(MayanNumber(7_999), .multiplication, MayanNumber(7_999))
        }
    }
}

// MARK: - ViewModel

@MainActor
struct CalculatorViewModelTests {
    @Test func flujoCompleto() {
        let vm = CalculatorViewModel()
        vm.drop(MayanDigit(3)!, onLevel: 0, of: .first)
        vm.drop(MayanDigit(1)!, onLevel: 1, of: .first)   // 23
        vm.select(.multiplication)
        vm.drop(MayanDigit(2)!, onLevel: 0, of: .second)  // 2
        #expect(vm.canCalculate)
        vm.calculate()
        #expect(vm.result?.value.value == 46)

        #expect(vm.continueWithResult())
        #expect(vm.decimalValue(of: .first) == 46)
        #expect(vm.decimalValue(of: .second) == nil)
        #expect(vm.activeOperand == .second)
    }

    @Test func editarInvalidaElResultado() {
        let vm = CalculatorViewModel()
        vm.drop(MayanDigit(4)!, onLevel: 0, of: .first)
        vm.drop(MayanDigit(2)!, onLevel: 0, of: .second)
        vm.calculate()
        #expect(vm.result != nil)
        vm.drop(MayanDigit(1)!, onLevel: 0, of: .first)
        #expect(vm.state == .editing)
    }

    @Test func restaNegativaMuestraErrorYSePuedeIntercambiar() {
        let vm = CalculatorViewModel()
        vm.drop(MayanDigit(2)!, onLevel: 0, of: .first)
        vm.drop(MayanDigit(9)!, onLevel: 0, of: .second)
        vm.select(.subtraction)
        vm.calculate()
        #expect(vm.error == .negativeResult)
        vm.swapOperands()
        vm.calculate()
        #expect(vm.result?.value.value == 7)
    }
}
