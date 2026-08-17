enum DocumentType {
  birthdayCard,
  characterCertificate,
  bonafideCertificate,
  leavingCertificate,
  experienceCertificate,
  meritCertificate,
  appreciationCertificate,
  resultCard,
  idCard,
  employeeCard,
  salarySlip,
  feeChallan,
  feeReceipt,
}

extension DocumentTypeX on DocumentType {
  String get label {
    return switch (this) {
      DocumentType.birthdayCard => 'Birthday Card',
      DocumentType.characterCertificate => 'Character Certificate',
      DocumentType.bonafideCertificate => 'Bonafide Certificate',
      DocumentType.leavingCertificate => 'Leaving Certificate',
      DocumentType.experienceCertificate => 'Experience Certificate',
      DocumentType.meritCertificate => 'Merit Certificate',
      DocumentType.appreciationCertificate => 'Appreciation Certificate',
      DocumentType.resultCard => 'Result Card',
      DocumentType.idCard => 'ID Card',
      DocumentType.employeeCard => 'Employee Card',
      DocumentType.salarySlip => 'Salary Slip',
      DocumentType.feeChallan => 'Fee Challan',
      DocumentType.feeReceipt => 'Fee Receipt',
    };
  }
}
