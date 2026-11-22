#!/usr/bin/env python3
"""Kiểm thử API thật trên SQL Server riêng của bài. Dữ liệu test có tiền tố AUDIT-."""
import json, urllib.request, urllib.error, time, base64, os
from cleanup_test_data import cleanup
BASE=os.environ.get('RENTAL_API_URL','http://127.0.0.1:5055/api')
HOST=BASE.removesuffix('/api')
checks=0

def call(method,path,data=None,token=None,expected=200,raw=None,content_type=None):
    global checks
    headers={}
    if token: headers['Authorization']='Bearer '+token
    if raw is not None: payload=raw;headers['Content-Type']=content_type
    else: payload=None if data is None else json.dumps(data).encode();headers['Content-Type']='application/json'
    req=urllib.request.Request(BASE+path,data=payload,headers=headers,method=method)
    try:
        with urllib.request.urlopen(req,timeout=20) as response: code=response.status;body=response.read()
    except urllib.error.HTTPError as e: code=e.code;body=e.read()
    assert (code in expected if isinstance(expected,tuple) else code==expected),(method,path,expected,code,body[:500])
    checks+=1
    return json.loads(body) if body else None

def upload(path,token,picture):
    boundary='RentalBoundary'
    raw=(f'--{boundary}\r\nContent-Disposition: form-data; name="File"; filename="test.png"\r\nContent-Type: image/png\r\n\r\n').encode()+picture+f'\r\n--{boundary}--\r\n'.encode()
    return call('POST',path,token=token,raw=raw,content_type='multipart/form-data; boundary='+boundary)

suffix=str(time.time_ns())

def run():
    admin=call('POST','/auth/login',{'email':'admin@rental.com','password':'Admin@123'})['token']
    member=call('POST','/auth/login',{'email':'member@rental.com','password':'Member@123'})['token']
    call('GET','/users',expected=401)
    call('GET','/users',token=member,expected=403)
    call('POST','/categories',{'name':'unauthorized'},token=member,expected=403)
    call('POST','/auth/login',{'email':'admin@rental.com','password':'wrong'},expected=401)
    call('GET','/auth/profile',token=admin)
    email='audit-'+suffix+'@rental.com'
    u=call('POST','/auth/register',{'email':email,'password':'Test@123','fullName':'Kiểm thử','phoneNumber':'0901234567'})
    call('POST','/auth/change-password',{'currentPassword':'wrong','newPassword':'Test@456'},token=u['token'],expected=400)
    call('POST','/auth/change-password',{'currentPassword':'Test@123','newPassword':'Test@456'},token=u['token'])
    call('POST','/auth/login',{'email':email,'password':'Test@456'})
    call('PUT',f"/users/{u['user']['id']}/roles",{'roles':['Admin']},token=admin)
    call('PUT',f"/users/{u['user']['id']}/status",{'isActive':False},token=admin)
    call('POST','/auth/login',{'email':email,'password':'Test@456'},expected=403)
    c=call('POST','/categories',{'name':'AUDIT-'+suffix,'description':'test'},token=admin,expected=201)
    cid=c['id']
    call('PUT',f'/categories/{cid}',{'name':c['name']+' edited','description':'updated','isActive':True},token=admin)
    d=call('POST','/devices',{'name':'AUDIT device','serialNumber':'AUDIT-'+suffix,'categoryId':cid,'rentalPricePerDay':100,'qrCode':'QR-'+suffix},token=admin,expected=201)
    did=d['id']
    call('GET',f'/devices/lookup?code=QR-{suffix}')
    call('GET',f'/devices?categoryId={cid}&pageSize=1&pageIndex=1')
    call('GET',f'/devices?keyword=AUDIT&pageSize=1&pageIndex=2')
    call('DELETE',f'/categories/{cid}',token=admin,expected=400)
    png=base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=')
    a=upload(f'/devices/{did}/upload-image',admin,png)['imageUrl']
    with urllib.request.urlopen(HOST+a) as response: assert response.read()==png
    b=upload(f'/devices/{did}/upload-image',admin,png)['imageUrl']
    try: urllib.request.urlopen(HOST+a);raise AssertionError('old image exists')
    except urllib.error.HTTPError as e: assert e.code==404
    call('POST','/rentals/checkout',{'startDate':'2026-11-13','expectedEndDate':'2026-11-20','shippingAddress':'Test','phoneNumber':'0901234567','items':[{'deviceId':did,'rentalDays':3}]},expected=401)
    order=call('POST','/rentals/checkout',{'startDate':'2026-11-13','expectedEndDate':'2026-11-20','shippingAddress':'Test','phoneNumber':'0901234567','items':[{'deviceId':did,'rentalDays':3}]},token=member,expected=201)
    assert order['totalAmount']==300 and order['totalDeposit']==90 and order['status']=='Pending'
    rid=order['id']
    call('POST','/rentals/checkout',{'startDate':'2026-11-13','expectedEndDate':'2026-11-20','shippingAddress':'Test','phoneNumber':'0901234567','items':[{'deviceId':did,'rentalDays':3}]},token=member,expected=400)
    call('GET',f'/rentals/{rid}',token=member)
    other=call('POST','/auth/register',{'email':'other-'+suffix+'@rental.com','password':'Test@123','fullName':'Other'})
    call('GET',f'/rentals/{rid}',token=other['token'],expected=403)
    call('DELETE',f'/devices/{did}',token=admin,expected=400)
    call('PUT',f'/rentals/{rid}/status',{'status':'Returned'},token=admin,expected=400)
    call('PUT',f'/rentals/{rid}/status',{'status':'Approved'},token=admin)
    for typ in ['DELIVERY','RETURN']:
        call('POST',f'/rentals/{rid}/handover',{'logType':typ,'handledBy':'Kho','signerName':'Khách','signatureData':'[[1,2],[3,4]]'},token=admin)
    logs=call('GET',f'/rentals/{rid}/handover',token=member);assert len(logs)==2
    assert call('GET',f'/devices/{did}')['status']=='Available'
    call('GET',f'/devices/{did}/history',token=admin)
    call('GET','/rentals?keyword=HD-&fromDate=2026-01-01&toDate=2026-12-31',token=admin)
    # Hai request thuê cùng máy: chỉ một request thành công.
    from concurrent.futures import ThreadPoolExecutor
    payload={'startDate':'2026-11-13','expectedEndDate':'2026-11-20','shippingAddress':'Race','phoneNumber':'0901234567','items':[{'deviceId':did,'rentalDays':1}]}
    with ThreadPoolExecutor(max_workers=2) as pool:
        attempts=list(pool.map(lambda _:call('POST','/rentals/checkout',payload,token=member,expected=(201,400)),range(2)))
    winners=[x for x in attempts if 'id' in x]
    assert len(winners)==1,attempts
    # Gửi lặp trạng thái Returned của đơn cũ không được giải phóng máy thuộc đơn mới.
    call('PUT',f'/rentals/{rid}/status',{'status':'Returned'},token=admin)
    assert call('GET',f'/devices/{did}')['status']=='Rented'
    call('PUT',f"/rentals/{winners[0]['id']}/status",{'status':'Cancelled'},token=admin)
    assert call('GET',f'/devices/{did}')['status']=='Available'
    # Thu hồi từng máy phải đồng bộ hợp đồng và giữ máy đã cho thuê lại.
    second=call('POST','/devices',{'name':'AUDIT device','serialNumber':'AUDIT-'+suffix+'-2','categoryId':cid,'rentalPricePerDay':100},token=admin,expected=201)
    secondId=second['id']
    partialPayload={**payload,'items':[{'deviceId':did,'rentalDays':1},{'deviceId':secondId,'rentalDays':1}]}
    partial=call('POST','/rentals/checkout',partialPayload,token=member,expected=201)
    partialId=partial['id']
    call('PUT',f'/devices/{did}/status',{'status':'Available'},token=member,expected=403)
    call('PUT',f'/devices/{did}/status',{'status':'Available'},token=admin,expected=400)
    call('PUT',f'/rentals/{partialId}/status',{'status':'Approved'},token=admin)
    call('PUT',f'/rentals/{partialId}/status',{'status':'Renting'},token=admin)
    call('PUT',f'/devices/{did}/status',{'status':'Available'},token=admin)
    state=call('GET',f'/rentals/{partialId}',token=admin)
    assert state['status']=='Renting' and next(i for i in state['items'] if i['deviceId']==did)['actualReturnDate'] is not None
    assert call('GET',f'/devices/{secondId}')['status']=='Rented'
    again=call('POST','/rentals/checkout',payload,token=member,expected=201)
    call('PUT',f'/rentals/{partialId}/status',{'status':'Returned'},token=admin)
    assert call('GET',f'/devices/{did}')['status']=='Rented'
    assert call('GET',f'/devices/{secondId}')['status']=='Available'
    call('PUT',f"/rentals/{again['id']}/status",{'status':'Cancelled'},token=admin)
    brokenOrder=call('POST','/rentals/checkout',{**payload,'items':[{'deviceId':secondId,'rentalDays':1}]},token=member,expected=201)
    brokenId=brokenOrder['id']
    call('PUT',f'/rentals/{brokenId}/status',{'status':'Approved'},token=admin)
    call('PUT',f'/rentals/{brokenId}/status',{'status':'Renting'},token=admin)
    call('PUT',f'/devices/{secondId}/status',{'status':'Broken'},token=admin)
    assert call('GET',f'/rentals/{brokenId}',token=admin)['status']=='Returned'
    assert call('GET',f'/devices/{secondId}')['status']=='Broken'
    history=call('GET',f'/devices/{secondId}/history',token=admin)
    assert history[0]['rental_status']=='RETURNED'
    # Separate unused device verifies deletion removes image.
    temp=call('POST','/devices',{'name':'AUDIT delete','serialNumber':'DELETE-'+suffix,'categoryId':cid,'rentalPricePerDay':1},token=admin,expected=201)
    image=upload(f"/devices/{temp['id']}/upload-image",admin,png)['imageUrl']
    call('DELETE',f"/devices/{temp['id']}",token=admin)
    try: urllib.request.urlopen(HOST+image);raise AssertionError('deleted device image exists')
    except urllib.error.HTTPError as e: assert e.code==404
    empty=call('POST','/categories',{'name':'AUDIT empty '+suffix},token=admin,expected=201)
    ci=upload(f"/categories/{empty['id']}/upload-image",admin,png)['imageUrl']
    call('DELETE',f"/categories/{empty['id']}",token=admin)
    try: urllib.request.urlopen(HOST+ci);raise AssertionError('deleted category image exists')
    except urllib.error.HTTPError as e: assert e.code==404
    print(f'PASS: {checks} API checks + image replacement/deletion and database integrity assertions')

if __name__ == "__main__":
    try:
        run()
    finally:
        cleanup(suffix)
