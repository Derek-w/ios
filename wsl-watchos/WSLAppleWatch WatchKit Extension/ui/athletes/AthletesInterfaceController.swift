//
//  AthletesInterfaceController.swift
//  WSLAppleWatch WatchKit Extension
//
//  Created by Scott Wang on 10/14/19.
//  Copyright © 2019 World Surf League. All rights reserved.
//

import WatchKit
import Foundation
import RxSwift

class AthletesInterfaceController: RxInterfaceController {
    private var athletesViewModel: AthletesViewModel!
    private var error = false
    
    @IBOutlet weak var athleteTable: WKInterfaceTable!

    private var event: Event?
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        athletesViewModel = AthletesViewModel()
     
        guard let event = context as? Event else { return }
        self.event = event
        bindViews()
    }
        
    private func bindViews() {
        guard let viewModel = athletesViewModel, let event = self.event else { return }
        
        disposeBag.insertAll(all:
            viewModel.athletes.subscribe { [weak self] event in
                guard let strongSelf = self, let athletes = event.element else { return }
                strongSelf.setupAthletes(athletes)
            },
            viewModel.error.subscribe { [weak self] event in
                guard let strongSelf = self else { return }
                strongSelf.setupError()
            }
        )

        viewModel.loadModel(event)
    }
    
    private func setupError() {
        error = true
        athleteTable.setNumberOfRows(1, withRowType: "AthleteRow")
        let controller = athleteTable.rowController(at: 0) as! SimpleRowController
        controller.label.setText("Error - Retry")
    }

    private func setupAthletes(_ athletes: [Athlete]) {
        if athletes.count == 0 {
            athleteTable.setNumberOfRows(1, withRowType: "AthleteRow")
            let controller = athleteTable.rowController(at: 0) as! SimpleRowController
            controller.label.setText("Loading...")
        } else {
            athleteTable.setNumberOfRows(athletes.count, withRowType: "AthleteRow")
            for index in 0..<athletes.count {
                let athlete = athletes[index]
                let controller = athleteTable.rowController(at: index) as! SimpleRowController
                controller.label.setText("\(athlete.displayName) Heat: \(athlete.heatNumber)")
                if (athlete.isActive) {
                    controller.label.setTextColor(.green)
                }
            }
        }
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        guard let viewModel = athletesViewModel else { return }
        if error, let event = self.event {
            error = false
            viewModel.loadModel(event)
            return
        }

        guard let athlete = viewModel.getAthleteAtIndex(rowIndex) else { return }
        guard let event = self.event else { return }
        configureConfirmationAlert(athlete, event: event)
    }
    
    private func configureConfirmationAlert(_ athlete: Athlete, event: Event) {
        
        let cancelAction = WKAlertAction(title: "Cancel", style: .cancel, handler:{})
        
        let okAction = WKAlertAction(title: "OK", style: .cancel, handler:{
            DispatchQueue.main.async {
                WKInterfaceController.reloadRootControllers(withNamesAndContexts: [("Stats", (event, athlete, TakeoverType.none) as AnyObject), ("StatsAux", (event, athlete) as AnyObject)])
            }
        })

        self.presentAlert(withTitle: athlete.displayName, message: "Press OK to start or Cancel to choose another competitor.", preferredStyle: .sideBySideButtonsAlert, actions: [okAction, cancelAction])
    }
}
