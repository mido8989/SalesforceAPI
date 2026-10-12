List<Contact> cons = [SELECT Id, Email FROM Contact WHERE Email LIKE '%&%'];
for (Contact c : cons) {
    c.Email = c.Email.replace('&', '');
}
update cons;
System.debug('Fixed: ' + cons.size());