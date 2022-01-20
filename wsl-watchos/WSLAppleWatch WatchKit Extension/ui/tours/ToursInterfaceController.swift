//
//  ToursInterfaceController.swift
//  WSLAppleWatch WatchKit Extension
//
//  Created by Scott Wang on 10/9/19.
//  Copyright © 2019 World Surf League. All rights reserved.
//

import WatchKit
import Foundation
import RxSwift

class ToursInterfaceController: RxInterfaceController {
    private var toursViewModel: ToursViewModel!
    private var error = false
    
    @IBOutlet weak var tourTable: WKInterfaceTable!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        toursViewModel = ToursViewModel()
        bindViews()
    }
    
    private func bindViews() {
        guard let viewModel = toursViewModel else { return }
        
        disposeBag.insertAll(all:
            viewModel.tours.subscribe { [weak self] event in
                guard let strongSelf = self, let tours = event.element else { return }
                strongSelf.setupTours(tours)
            },
            viewModel.error.subscribe { [weak self] event in
                guard let strongSelf = self else { return }
                strongSelf.setupError()
            }
        )
        
        viewModel.loadModel()
    }
    
    private func setupError() {
        error = true
        tourTable.setNumberOfRows(1, withRowType: "TourRow")
        let controller = tourTable.rowController(at: 0) as! SimpleRowController
        controller.label.setText("Error - Retry")
    }
    
    private func setupTours(_ tours: [Tour]) {
        if tours.count == 0 {
            tourTable.setNumberOfRows(1, withRowType: "TourRow")
            let controller = tourTable.rowController(at: 0) as! SimpleRowController
            controller.label.setText("Loading...")
        }
        tourTable.setNumberOfRows(tours.count, withRowType: "TourRow")
        for index in 0..<tours.count {
            let tour = tours[index]
            let controller = tourTable.rowController(at: index) as! SimpleRowController
            controller.label.setText(tour.name)
        }
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        guard let viewModel = toursViewModel else { return }
        if error {
            error = false
            viewModel.loadModel()
            return
        }
        
        guard let tour = viewModel.getTourAtindex(rowIndex) else { return }
        pushController(withName: "Events", context: tour)
    }
}
