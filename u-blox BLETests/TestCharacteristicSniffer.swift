import XCTest
import CoreBluetooth
import Cuckoo
@testable import U_blox

class TestCharacteristicSniffer: XCTestCase {
    var peripheral: MockUbloxPeripheral!
    var cbFifo: CBMutableCharacteristic!
    var cbCredits: CBMutableCharacteristic!

    override func setUp() {
        peripheral = MockUbloxPeripheral(peripheral: nil)
        stub(peripheral) { mock in
            when(mock.readValue(for: any())).thenDoNothing()
            when(mock.setNotify(true, for: any())).thenDoNothing()
        }
        cbFifo = CBMutableCharacteristic(type: UbloxCharacteristic.serialPortFifo.cbUuid, properties: .read, value: nil, permissions: .readable)
        cbCredits = CBMutableCharacteristic(type: UbloxCharacteristic.serialPortCredits.cbUuid, properties: .read, value: nil, permissions: .readable)
        super.setUp()
    }
    
    override func tearDown() {
        peripheral = nil
        super.tearDown()
    }

    func test_DoesNotSetNotifyOnOnlyRead() {
        let sniffer = CharacteristicSniffer(for: peripheral, readAndNotify: [], onlyRead: [UbloxCharacteristic.serialPortCredits])
        sniffer.onCharacteristicDiscovery([cbCredits])
        verify(peripheral, never()).setNotify(true, for: any())
    }
    
    func test_ReadsOnlyRead() {
        let sniffer = CharacteristicSniffer(for: peripheral, readAndNotify: [], onlyRead: [UbloxCharacteristic.serialPortCredits])
        sniffer.onCharacteristicDiscovery([cbCredits])
        verify(peripheral, times(1)).readValue(for: any())
    }
    
    func test_SetsNotifyOnNotifyAndRead() {
        let sniffer = CharacteristicSniffer(for: peripheral, readAndNotify: [UbloxCharacteristic.serialPortFifo], onlyRead: [])
        sniffer.onCharacteristicDiscovery([cbFifo])
        verify(peripheral, times(1)).setNotify(true, for: any())
    }
    
    func test_ReadsOnNotifyAndRead() {
        let sniffer = CharacteristicSniffer(for: peripheral, readAndNotify: [UbloxCharacteristic.serialPortFifo], onlyRead: [])
        sniffer.onCharacteristicDiscovery([cbFifo])
        verify(peripheral, times(1)).readValue(for: any())
    }
    
    func test_DoesNotReadUnrelatedCharForOnlyRead() {
        let sniffer = CharacteristicSniffer(for: peripheral, readAndNotify: [], onlyRead: [UbloxCharacteristic.serialPortFifo])
        sniffer.onCharacteristicDiscovery([cbCredits])
        verify(peripheral, never()).readValue(for: any())
    }
    
    func test_DoesNotReadUnrelatedForNotifyAndRead() {
        let sniffer = CharacteristicSniffer(for: peripheral, readAndNotify: [UbloxCharacteristic.serialPortCredits], onlyRead: [])
        sniffer.onCharacteristicDiscovery([cbFifo])
        verify(peripheral, never()).readValue(for: any())
    }
    
    func test_DoesNotSetNotifyOnRelatedFprNotifyAndReaad() {
        let sniffer = CharacteristicSniffer(for: peripheral, readAndNotify: [UbloxCharacteristic.serialPortFifo], onlyRead: [])
        sniffer.onCharacteristicDiscovery([cbCredits])
        verify(peripheral, never()).setNotify(true, for: any())
    }
}
