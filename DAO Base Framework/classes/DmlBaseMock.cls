public abstract class DmlBaseMock implements DmlInterface {
	protected List<SObject> records;
	private static final String ID_FIELD = 'Id';
	
	public DmlBaseMock(List<SObject> records) {
		this.records = records;
	}

	public List<SObject> getRecords() {
		return this.records;
	}

	public void addId(SObject record) {
		SObjectType sot;
		if (record.get(ID_FIELD) == null || record.get(ID_FIELD) == 'null') {
			sot = record.getSObjectType();
			record.put(ID_FIELD, MockIdGenerator.getMockId(sot));
		}
	}

	public void insertRecords(List<SObject> newRecords) {
		for (SObject record : newRecords) {
			if (record.get(ID_FIELD) != null && record.get(ID_FIELD) != 'null') {
				throw new DmlException('Cannot insert a record with an ID.');
			}
			addId(record);
			this.records.add(record);
		}
	}

	public void updateRecords(List<SObject> records) {
		for (SObject record : records) {
			if (record.get(ID_FIELD) == null || record.get(ID_FIELD) == 'null') {
				throw new DmlException('Records to update must have a record Id.');
			}
			this.records.add(record);
		}
	}

	public void upsertRecords(List<SObject> records) {
		for (SObject record : records) {
			addId(record);
		}

		this.records.addAll(records);
	}

	public void deleteRecords(List<SObject> records) {
		Set<SObject> recordsSet = new Set<SObject>();
		recordsSet.addAll(this.records);

		for (SObject record : records) {
			if (record.get(ID_FIELD) == null || record.get(ID_FIELD) == 'null') {
				throw new DmlException('Records to delete must have a record Id.');
			}
			if (recordsSet.contains(record)) {
				recordsSet.remove(record);
			}
		}

		this.records.clear();
		this.records.addAll(recordsSet);
	}
}