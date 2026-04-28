trigger ContactTrigger on Contact (before insert, before update, after insert, after update) {

	switch on Trigger.operationType {
		when BEFORE_INSERT {
			ContactTriggerFacade.onBeforeInsert(Trigger.new);
		}
		when BEFORE_UPDATE {
			ContactTriggerFacade.onBeforeUpdate(Trigger.new, Trigger.oldMap);
		}
		when AFTER_INSERT {
			ContactTriggerFacade.onAfterInsert(Trigger.new);
		}
		when AFTER_UPDATE {
			ContactTriggerFacade.onAfterUpdate(Trigger.new, Trigger.oldMap);
		}
	}
}