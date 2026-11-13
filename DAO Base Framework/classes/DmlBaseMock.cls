public abstract class DmlBaseMock implements DmlInterface {
	protected List<SObject> records;
	private static final String ID_FIELD = 'Id';

	public DmlBaseMock(List<SObject> records) {
		this.records = records;
	}

	public List<SObject> getRecords() {
		return this.records;
	}

	public void addExistingRecords(List<SObject> existingRecords) {
		for (SObject record : existingRecords) {
			if (!hasId(record)) {
				throw new DmlException('Existing records must have a record Id.');
			}
		}

		this.records.addAll(existingRecords);
	}

	public void insertRecords(List<SObject> newRecords) {
		for (SObject record : newRecords) {
			if (hasId(record)) {
				throw new DmlException('Cannot insert a record with an ID.');
			}
			addId(record);
			this.records.add(record);
		}
	}

	public void updateRecords(List<SObject> changedRecords) {
		for (SObject record : changedRecords) {
			if (!hasId(record)) {
				throw new DmlException('Records to update must have a record Id.');
			}
			replaceRecord(record);
		}
	}

	public void upsertRecords(List<SObject> upsertedRecords) {
		for (SObject record : upsertedRecords) {
			if (hasId(record)) {
				replaceRecord(record);
			} else {
				addId(record);
				this.records.add(record);
			}
		}
	}

	public void deleteRecords(List<SObject> deletedRecords) {
		Set<Id> deletedIds = new Set<Id>();

		for (SObject record : deletedRecords) {
			if (!hasId(record)) {
				throw new DmlException('Records to delete must have a record Id.');
			}
			deletedIds.add(record.Id);
		}

		List<SObject> remainingRecords = new List<SObject>();
		for (SObject record : this.records) {
			if (!deletedIds.contains(record.Id)) {
				remainingRecords.add(record);
			}
		}

		this.records.clear();
		this.records.addAll(remainingRecords);
	}

	private Boolean hasId(SObject record) {
		return record.get(ID_FIELD) != null;
	}

	private void addId(SObject record) {
		record.put(ID_FIELD, MockIdGenerator.getMockId(record.getSObjectType()));
	}

	private void replaceRecord(SObject changedRecord) {
		for (Integer index = 0; index < this.records.size(); index++) {
			if (this.records[index].Id == changedRecord.Id) {
				this.records[index] = changedRecord;
				return;
			}
		}

		throw new DmlException('Record to update does not exist: ' + changedRecord.Id);
	}
}