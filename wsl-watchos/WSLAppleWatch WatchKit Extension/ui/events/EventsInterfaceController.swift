//
//  EventsInterfaceController.swift
//  WSLAppleWatch WatchKit Extension
//
//  Created by Scott Wang on 10/15/19.
//  Copyright © 2019 World Surf League. All rights reserved.
//

import WatchKit

class EventsInterfaceController: RxInterfaceController {
    private var eventsViewModel: EventsViewModel!
    private var error = false
    private var loaded = false
    
    @IBOutlet weak var eventsTable: WKInterfaceTable!
    
    private var tour: Tour?
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        eventsViewModel = EventsViewModel()
        
        guard let tour = context as? Tour else { return }
        self.tour = tour
        bindViews()
        
    }
    
    private func bindViews() {
        guard let viewModel = eventsViewModel, let tour = self.tour else { return }

        disposeBag.insertAll(all:
            viewModel.events.subscribe { [weak self] event in
                guard let strongSelf = self, let events = event.element else { return }
                strongSelf.setupEvents(events)
            },
            viewModel.error.subscribe { [weak self] event in
                guard let strongSelf = self, let errorString = event.element else { return }
                strongSelf.setupError(errorString)
            }
        )
        
        viewModel.loadModel(tour)
        loaded = true
    }
    
    private func setupError(_ errorString: String) {
        error = true
        eventsTable.setNumberOfRows(1, withRowType: "EventRow")
        let controller = eventsTable.rowController(at: 0) as! SimpleRowController
        controller.label.setText("Error - Retry")
    }
    
    private func setupEvents(_ events: [Event]) {
        if events.count == 0 {
            eventsTable.setNumberOfRows(1, withRowType: "EventRow")
            let controller = eventsTable.rowController(at: 0) as! SimpleRowController
            controller.label.setText(loaded ? "No active events" : "Loading...")            
        } else {
            eventsTable.setNumberOfRows(events.count, withRowType: "EventRow")
            for index in 0..<events.count {
                let event = events[index]
                let controller = eventsTable.rowController(at: index) as! SimpleRowController
                controller.label.setText(event.name)
            }
        }
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        guard let viewModel = eventsViewModel else { return }
        if error, let tour = self.tour {
            error = false
            viewModel.loadModel(tour)
            return
        }
        
        guard let event = viewModel.getEventAtIndex(rowIndex) else { return }
        pushController(withName: "Athletes", context: event)
    }
}
